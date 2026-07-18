# Phase 3 Checkpoint: Platform Administrator vs. Tenant Administrator

Same evidence standard as [`phase1_tenancy_checkpoint.md`](./phase1_tenancy_checkpoint.md) and [`phase2_trip_model_checkpoint.md`](./phase2_trip_model_checkpoint.md).

## 1. What this phase found, and what it does not fix

A direct audit of every role-gated route (not a re-read of the Constitution) found: `UserController` and `AuditLogController` were gated by role (`"admin"`) with **zero organisation scoping** — any tenant's own `"admin"` user could view/edit every user across every organisation and read the entire platform's audit log. `OperatorController` had the identical gap (missed in Phase 1's sweep, since Operator only became Organisation's child profile mid-flight there) — any manager/admin, from any organisation, could create, edit, or archive *any* organisation's Operator profile, including onboarding a brand-new tenant.

Asked what a tenant administrator should be scoped to, the answer described a full capability-based permission system: `organisation_memberships`, `role_permissions`, multi-role-per-user, a Platform/Tenant/Departmental/Operational role hierarchy, HR/payroll/finance/accounting field-level separation of duties, and break-glass support access. That is a distinct, large initiative — building it in the same pass as closing an active authorization leak would mean shipping neither safely. **This phase closes the leak using the existing single-role-per-user model, extended with two role strings instead of one.** The capability/permission-table model, multi-organisation membership, and departmental data separation are named in §5 as not started, not silently dropped.

## 2. What changed

### 2.1 The role split

`"admin"` retired, replaced by two distinct strings — not inferred from `organisation_id`, an explicit, separately-checkable role:

- **`platform_admin`** — Miway's own staff. No organisation (enforced, see below). Sees and manages across every tenant.
- **`tenant_admin`** — a tenant's own top-tier staff. Has an organisation (enforced). Scoped to it, the same as every other Phase-1-scoped resource.

`User.changeset/2` and `registration_changeset/2` gained `validate_role_organisation_pairing/1`: `platform_admin` requires `organisation_id: nil`; every other role requires one. This is a data-layer invariant, not a convention — a `platform_admin` tied to an organisation, or a `tenant_admin` floating without one, is now a changeset error, not just something authorization checks are trusted to notice.

Migration `20260718100001_split_admin_into_platform_and_tenant_admin.exs`: backfilled every existing `"admin"` user to `platform_admin` (if `organisation_id` was nil) or `tenant_admin` (if set), via a three-step constraint dance (widen the check constraint to allow both old and new values → backfill → tighten to the final set, retiring `"admin"` for good). Real result on the dev database: `Sam` (`organisation_id: nil`) → `platform_admin`.

### 2.2 `/users` — now organisation-scoped

- `Users.list_users_paginated/2` gained an `:organisation_id` filter opt (same `:all`/`nil`/id convention as every Phase 1 context function).
- `UserController` — `show`/`edit`/`update`/`activate`/`deactivate` gated by `with_organisation_access` (reusing `Authorization.can_access_organisation?/2` from Phase 1 unchanged — it already does exactly the right thing here: a `tenant_admin`'s own `organisation_id` never equals `nil`, so they can never reach a `platform_admin` user, by the existing logic, no new function needed).
- `create`/`update` run submitted params through `sanitize_params/2`: a `platform_admin`'s params are trusted as submitted (unchanged, already-broad power); a `tenant_admin`'s are corrected server-side — `organisation_id` is always forced to their own (can't create or reassign a user into another organisation, or to platform-level by nulling it out), and a submitted `role: "platform_admin"` is silently downgraded to `"tenant_admin"` (can't self-escalate or grant platform authority to anyone else).
- `UserHTML.role_options/1` hides "Platform Administrator" from the dropdown for a `tenant_admin` caller — the UI half of the guard; `sanitize_params/2` is the half that still holds if the form is bypassed entirely (verified by a test that POSTs `role: "platform_admin"` directly, see §3).

### 2.3 `/audit-log` — now platform-only, `/users` — either admin tier

The router's single `:require_admin` pipeline (`roles: ["admin"]`) is now two: `:require_admin` (`["platform_admin", "tenant_admin"]`, gates `/users` — `UserController` does the org-scoping internally) and `:require_platform_admin` (`["platform_admin"]` only, gates `/audit-log` — the platform-wide trail a tenant administrator must not see).

`audit_logs` gained a nullable `organisation_id` (migration `20260718100007`, FK to `organisations`, `on_delete: :nilify_all`) — nullable on purpose: events with no actor (a failed login against an unknown email) have no tenant to attribute to and correctly stay platform-only visible rather than guessed. `Administration.log/2` derives it from the actor's *current* organisation automatically (`actor_organisation_id/1`) when not explicitly passed, so none of its 7 call sites needed touching. `Administration.list_recent_audit_logs/2` gained the same `:organisation_id` opt as every other Phase 1/2 list function — unused by `AuditLogController` today (platform-only route, so it's always `:all`), but there so a tenant-facing, org-scoped audit view is a query away, not a redesign, whenever that's built.

### 2.4 `OperatorController` — closed, not just relabeled

- `new`/`create` (onboarding a new tenant) — `platform_admin` only, via a new local `require_platform_admin` plug using `Authorization.platform_admin?/1` (added alongside `platform_level?/1`; deliberately a *role* check, not an `organisation_id`-nil check — the whole point of this phase is that "which data can I see" and "what actions can I take" must be checked independently, never inferred from each other).
- `index` — `Routes.list_operators_with_route_counts/1` gained an `:organisation_id` opt; tenant staff (any role) now see only their own organisation's Operator, platform staff see all. The "+ Add Company" button on that page is now hidden from anyone but a `platform_admin` (UI-only fix — the route itself was already correctly blocked; this just stops presenting an action that would 302 with a flash).
- `show`/`edit`/`update`/`delete` — `with_organisation_access` (a tenant's own manager/tenant_admin/platform_admin can still manage their own Operator's branding/routes/schedules — that's normal self-service, not onboarding); everyone else redirected with a flash, matching every other Phase 1 controller's convention.

## 3. Tests added this phase (20 new, all passing)

| File | Tests | What it proves |
|---|---|---|
| `test/fleet_mint_web/controllers/user_controller_test.exs` | 9 | A manager (below either admin tier) can't reach `/users` at all; `tenant_admin`'s index/show/edit are organisation-scoped both ways; creating/updating a user forces the caller's own organisation and downgrades a submitted `platform_admin` role, both via real HTTP requests with tampered params; a `platform_admin` retains full cross-organisation power |
| `test/fleet_mint_web/controllers/operator_controller_test.exs` | 6 | `tenant_admin` and `manager` both rejected from creating a new operator (with a DB check that nothing was written); `platform_admin` can; `tenant_admin` blocked from editing another organisation's operator (with a DB check the name wasn't changed) but can edit their own; index is organisation-scoped |
| `test/fleet_mint_web/controllers/audit_log_controller_test.exs` | 5 | `tenant_admin` redirected away from `/audit-log`; `platform_admin` reaches it; `Administration.log/2` correctly derives `organisation_id` from a known actor, stays `nil` for an unknown one, and `list_recent_audit_logs/2`'s organisation filter actually isolates events |

Also manually exercised against a running dev server before writing the above (per the pattern from the trip-matching UI): logged in as a real throwaway `platform_admin` and `tenant_admin`, confirmed the `/users/new` role dropdown correctly shows/hides "Platform Administrator", `/audit-log` 200s vs. redirects, and the `/operators` "Add Company" button now only renders for a `platform_admin` — this is what caught the stale button, which none of the automated tests were checking for (they test the route, not "does the UI still dangle a link to a blocked action").

## 4. Verification (reproducible)

```bash
mix test
mix test 2>&1 | grep -E "^\s*[0-9]+\) test" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]*//' | sort > current_failures.txt
diff current_failures.txt phase1_baseline.txt   # from docs/phase1_tenancy_checkpoint.md section 7 — empty output = proof
```

Actual result: **172 tests, 139 passing, 33 known pre-existing failures — byte-for-byte identical to the Phase 1 baseline list (`diff` exit 0), 0 new failures.** 20 new tests, all passing, none among the 33.

## 5. What is explicitly not built

Per the Constitutional answer this phase was scoped against, all of the following describe the intended end state and are real, sizeable, separate pieces of work — named here so they are not mistaken for done:

- **Capability-based permissions** (`role_permissions`, granular strings like `organisation.users.manage`) — roles here are still the same flat `role` string column as before, just with two admin tiers instead of one. No permission graph, no per-action grants independent of role.
- **`organisation_memberships`** (a user belonging to more than one organisation, or holding a platform-staff membership separate from a tenant one) — `users.organisation_id` is still a single nullable column. A user is exactly one of "platform" or "one tenant," never both, never several.
- **Departmental Administrator / Operational User granularity, and HR/payroll/finance/accounting field-level separation of duties** — a `tenant_admin` today can see everything within their own organisation that any other role there can see (scoped by organisation, not further restricted by department or data sensitivity). Nothing in this codebase currently flags a field as "confidential" (salary, banking details, disciplinary records) versus ordinary operational data, so there is no existing boundary to wire a permission check onto yet — that flagging work would have to come first.
- **Controlled/break-glass support access** for Miway staff into a specific tenant's data (named-purpose, time-limited, banner, expiry) — a `platform_admin` today has unrestricted, permanent, silent access to every tenant, exactly as before this phase; this phase did not add or remove that.
- **A tenant-facing, organisation-scoped audit view** — `Administration.list_recent_audit_logs/2`'s `:organisation_id` opt exists and is tested, but no route/controller exposes it to a `tenant_admin`; `/audit-log` stays `platform_admin`-only.
- **The public self-registration form's `role: "staff"` default** — `AuthController.create/2` already forces role away from anything meaningful before insert, but `"staff"` is not itself a valid role string (pre-existing, unrelated to this phase — self-registration was already effectively non-functional before this work and remains so).

---

**Commit representing Phase 3 completion: recorded in the same commit as this checkpoint.**
