# Phase 4 Checkpoint: Deeper Audit Logging

Same evidence standard as the Phase 1–3 checkpoints.

## 1. What this phase found

Before this phase, `Administration.log/2` had exactly **7 call sites**, all in `AuthController`/`TwoFactorController` — login and 2FA events only. Every administrative action the Phase 3 checkpoint restricted (who can create a user, who can promote someone to `platform_admin`, who can onboard a new tenant, who gets blocked from another organisation's records) left **zero trace**. A `tenant_admin` repeatedly probing another organisation's user list, or attempting to grant themselves `platform_admin`, would fail silently — correctly rejected, but invisible to any future investigation.

Instrumenting every mutating action across all ~23 controllers in the app is a distinct, much larger project (see §4). This phase scoped to the highest-value, most security-relevant surface: **the exact control-plane actions Phase 3 just restricted** — `UserController` and `OperatorController` — both the successful admin-lifecycle actions and the blocked unauthorized attempts.

## 2. What changed

### 2.1 A shared `client_ip/1` helper

`get_ip/1` was already duplicated privately in `AuthController` and `TwoFactorController`; adding audit calls to two more controllers would have made it four copies of the same six lines. Extracted to `FleetMintWeb.ControllerHelpers.client_ip/1`, imported automatically into every controller via `FleetMintWeb.controller/0` (the `use FleetMintWeb, :controller` macro) — the two existing private copies were removed in favor of it, not left duplicated alongside it.

### 2.2 New events logged

| Event | Where | Fires when |
|---|---|---|
| `user_created` | `UserController.create/2` | Any user is created — actor, new user's role and organisation in metadata |
| `user_role_changed` | `UserController.update/2` | A user's role actually changes (compares before/after; a no-op update logs nothing) |
| `user_activated` / `user_deactivated` | `UserController.activate/2` / `deactivate/2` | Every time, unconditionally |
| `role_escalation_attempt_blocked` | `UserController` create/update | A `tenant_admin` submits `role: "platform_admin"` in either form — logged *before* `sanitize_params/2` silently downgrades it, so the attempt itself is on record even though it never took effect |
| `cross_tenant_access_denied` | `UserController` + `OperatorController`, in `with_organisation_access/2`'s rejection branch | Any request against another organisation's user or operator |
| `operator_created` | `OperatorController.create/2` | A new tenant is onboarded — name and new organisation_id in metadata |
| `operator_archived` | `OperatorController.delete/2` | An operator is archived |
| `platform_only_action_denied` | `OperatorController.require_platform_admin/2`'s rejection branch | A `tenant_admin` or `manager` attempts `new`/`create` on an operator |

All of it reuses the existing `Administration.log/2` (unchanged internally) and the `organisation_id` auto-derivation from Phase 3 — none of these new call sites pass `organisation_id` explicitly; it's still derived server-side from the acting user, exactly as it already was for login events.

## 3. Tests added this phase (9 new, all passing)

Added as an `"audit logging"` describe block in each of the two existing controller test files (co-located with the actions they describe, rather than a separate audit-only test file):

| File | Tests | What it proves |
|---|---|---|
| `test/fleet_mint_web/controllers/user_controller_test.exs` | 5 | `user_created` carries the right actor/role/org; `user_activated`/`user_deactivated` both fire; `user_role_changed` carries the correct before/after; `cross_tenant_access_denied` fires with the right target; `role_escalation_attempt_blocked` fires and names the attempted role |
| `test/fleet_mint_web/controllers/operator_controller_test.exs` | 4 | `operator_created`, `operator_archived`, `platform_only_action_denied`, `cross_tenant_access_denied` — each via a real HTTP request, asserted against the actual `audit_logs` row written |

## 4. Verification (reproducible)

```bash
mix test
mix test 2>&1 | grep -E "^\s*[0-9]+\) test" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]*//' | sort > current_failures.txt
diff current_failures.txt phase1_baseline.txt   # docs/phase1_tenancy_checkpoint.md section 7 — empty = proof
```

Actual result: **181 tests, 148 passing, 33 known pre-existing failures — byte-for-byte identical to the Phase 1 baseline (`diff` exit 0), 0 new failures.** 9 new tests, all passing, none among the 33.

## 5. What is explicitly not built

- **The other ~21 controllers with create/update/delete actions** (buses, vehicles, drivers, schedules, bookings, cashing_reports, expenditures, freight clients/orders/trips/invoices, routes, etc.) have no audit logging at all. This phase deliberately scoped to the control-plane (who can administer who), not the full operational surface. Extending the same `Administration.log/2` call pattern to those is mechanical repetition of what's here, not a design question — a later phase's work, not started.
- **No generic instrumentation mechanism** (a plug, a Multi step builder mirroring `Accounting.multi_insert_entry/3`) was built to make future instrumentation cheaper. Each of the 9 new call sites is a direct `Administration.log/2` call, matching the existing 7 call sites' style exactly rather than introducing a second, different pattern alongside it. Worth revisiting if/when the other 21 controllers get instrumented — hand-writing ~60+ more call sites the same way would be the point at which a shared helper earns its complexity.
- **`Administration.log/2`'s own failure handling** — a failed audit-log insert (e.g. a bad changeset) is still silently swallowed (`Repo.insert/1`'s result is discarded, `:ok` returned regardless). Unchanged from before this phase; not touched, since the events it's now called with are all hardcoded literals that can't realistically fail validation.
- **A tenant-facing audit view** — still not built (named in the Phase 3 checkpoint too). A `tenant_admin` now generates far more audit trail than before this phase (their own admin actions), but still has no UI to see any of it — only a `platform_admin` can view `/audit-log`, and it shows every organisation's events.

---

**Commit representing Phase 4 completion: recorded in the same commit as this checkpoint.**
