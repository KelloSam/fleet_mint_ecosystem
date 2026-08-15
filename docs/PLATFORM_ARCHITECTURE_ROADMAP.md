# FleetMint Platform Architecture & Implementation Roadmap

**Document Code:** FMT-PAIR-001
**Document Class:** Product Architecture & Implementation Control
**Parent Governance:** Miway Enterprise Implementation Blueprint (MIW-EIB-001)
**Product Governance:** FleetMint Constitution (Working Draft, Version 1.0)
**Status:** Controlled Working Document
**Source of Truth:** `docs/PLATFORM_ARCHITECTURE_ROADMAP.md`

> This document shall describe verified as-built architecture as fact,
> approved near-term architecture as committed direction, and longer-term
> architecture as explicitly identified target or proposal. Future design
> shall never be represented as implemented capability.

This is the document to consult when asking "where did we stop, and what do
we build next." It sits between the governance documents (the Blueprint
defines *how* Miway engineers; the Constitution defines *what FleetMint is*)
and the phase checkpoints (`docs/phaseN_*.md`, which prove *what was
actually completed*). Everything in §1 below was verified directly against
the running codebase on 2026-08-15, not recalled from memory or from prior
checkpoints — one of the findings in §1.9 is a direct result of that
discipline.

---

## 1. As-Built Architecture (Phases 1–5) — Fact

### 1.1 Stack and environment

Phoenix 1.7 / Ecto / PostgreSQL 16. Dev server on port 4004, dev database
`fleet_mint_dev` on port 5433. Guardian JWT for authentication, sessions
carry a `user_token`. CI runs on GitHub Actions (`.github/workflows/`) on
every push/PR to `master`: `mix format --check-formatted`, `mix compile`,
`mix ecto.create && mix ecto.migrate` against a real Postgres service
container, then `mix test`. As of the Phase 5 checkpoint, the full suite is
**242 tests, 0 failures** — the first clean baseline in the project's
history; CI confirmed green on the corresponding push.

### 1.2 Tenancy model

`FleetMint.Identity.Organisation` is the tenant root (the Constitution's
"Company"). `Transport.Fleet.Operator` — the pre-existing table of 28
Zambian bus companies — is `belongs_to :organisation`, an optional
passenger-transport brand/profile of an Organisation, not the tenant root
itself: cargo-only or institutional tenants have no Operator at all.
`users.organisation_id` is `nil` for platform-level staff (Miway's own
team, sees every organisation) or set for tenant staff (scoped to one
organisation). `Identity.Authorization.platform_level?/1` and
`can_access_organisation?/2` are the canonical checks;
`FleetMintWeb.Plugs.TenantScopePlug` assigns
`conn.assigns.organisation_scope` (`:all` or an organisation_id) on every
authenticated request. Roles: `platform_admin` / `tenant_admin` / `manager`
/ `cashier`, enforced as a data-layer invariant (a user's org/role pairing
is validated in the changeset, not just convention).

### 1.3 Context inventory (verified against `lib/fleet_mint/` directly)

| Context | Schemas | Covers |
|---|---|---|
| `Identity` | `User`, `Organisation`, `Authentication`, `Authorization`, `Guardian`, `TwoFactor` | Auth, tenancy root, RBAC |
| `Transport.Fleet` | `Vehicle`, `Bus`, `BusProfile`, `TruckProfile`, `Operator`, `Branch`, `Terminal`, `FuelLog`, `VehicleMaintenance` | Physical assets, operator brand, org sub-structure (see §1.9) |
| `Transport.Routes` | `Route` | Route definitions (deliberately unscoped — see §3) |
| `Transport.Trips` | `Schedule`, `Trip`, `MinibusTrip` | The Route→Schedule→Trip model (§1.5) |
| `Transport.Ticketing` | `Booking`, `Ticket` | Passenger bookings and tickets |
| `Transport.Boarding` | `BusCheckpoint` | Boarding/checkpoint validation |
| `HR` | `Driver` | Driver records only — see §2's HR row |
| `Finance` | `CashingReport`, `CashingReportTrip`, `Expenditure`, `Report`, `Reconciliation` | Cash collection, expenditure, weekly reports |
| `Accounting` | `LedgerEntry` | Single-entry cash ledger (deliberate scope — see §2) |
| `Cargo` | `Client`, `Order`, `Trip`, `TripMilestone`, `Invoice` | Freight/logistics |
| `Administration` | `AuditLog`, `Complaint`, `OperationLog` | Audit trail, passenger complaints, operational logging |
| `Reporting` | `PdfGenerator` | PDF report generation |

60 migrations total. Two dead modules (`Payments`, `Ticketing` top-level —
not to be confused with `Transport.Ticketing`) were identified and deleted
in the 2026-07-05 accounting-core work; not present in the current tree.

### 1.4 Financial audit trail

`CashingReport` and `Expenditure` carry `created_by_id`/`updated_by_id`
(server-set only) and `archived_at` (soft delete — the row survives,
excluded from normal listings via `where: is_nil(archived_at)`).
`Administration.log/2` fires on create/update/delete for both, carrying
before/after values in metadata. Expenditure edit/update/delete is
manager+ only. A single-entry cash ledger (`Accounting.LedgerEntry`) is the
one source every money-writing path (bookings, cashing reports,
expenditures, freight invoices, fuel/maintenance costs) writes through —
`Finance.Reconciliation` reads from it directly rather than cross-checking
disconnected tables.

### 1.5 Route → Schedule → Trip model

Built GTFS-style: `Route` (top of hierarchy) → `Schedule` (belongs_to
route/vehicle/driver/conductor/operator — the *usual* assignment) → `Trip`
(belongs_to schedule/organisation, with its own nullable
vehicle/driver/conductor overrides — the *actual* assignment for one
travel date). A composite `(trip_id, organisation_id)` foreign key is the
mechanism that lets every child table (`bus_checkpoints`,
`cashing_report_trips`) prove it belongs to the same tenant as its Trip —
a plain `trip_id` FK alone can't prove that. `cashing_report_trips` is a
staged, confidence-scored allocation table (one report can cover several
trips or vice versa); `Finance.attempt_trip_match/1` only auto-matches
when the derivation is unambiguous, never fabricates a link.

### 1.6 Freight/Cargo domain

`freight_clients.organisation_id` is the authoritative cargo tenant root;
`Order`/`Invoice` derive via `client_id`, `Trip` derives via `vehicle_id`.
Trip assignment is validated against the order's client organisation and
the vehicle's remaining payload capacity on every create/update path (not
just the controller's usual entry point). Cancelling a trip releases its
still-open orders back to `pending`.

### 1.7 Security hardening (Aug 2026 org-scoping sweep)

Beyond the original Phase 1 scoping (schedules, bookings, vehicles, buses,
drivers, cashing reports, expenditures, freight), a later sweep closed 13
further cross-tenant gaps: fuel logs, vehicle maintenance, minibus trips,
ticket show/validate, weekly report edit/delete (which cascades to delete
cashing reports/expenditures — a real cross-tenant destruction path before
the fix), reconciliation aggregates, PDF report downloads,
`operation_logs`/`complaints` (both needed a real `organisation_id`
migration), `/api/notifications`, and public-booking operator/schedule
cross-checking. Full detail: `docs/phase5_hardening_checkpoint.md`.

### 1.8 Test-suite and process discipline

Every phase (1 through 5) has an in-repo, evidence-based checkpoint
(`docs/phase1_tenancy_checkpoint.md` through `phase5_hardening_checkpoint.md`)
built from reproducible verification commands (exact-name test-failure
diffs, authenticated-HTTP-request tests proving cross-tenant access is
rejected at the controller level, not just the query filter). This is
genuinely stronger evidence discipline than most of what MIW-EIB-001 itself
asks for as a minimum (confirmed in the Blueprint cross-reference done
2026-08-14 — see chat history; not reproduced as a separate document here
per the "don't add documents until proven necessary" principle this
document itself is trying to uphold).

### 1.9 A correction this document exists to make

`Transport.Fleet.Branch` and `Transport.Fleet.Terminal` schemas, full
context CRUD (`list_branches/1`, `create_branch/1`, etc.), and a nullable
`bookings.terminal_id` column **already exist** — added in commit
`afee844` (2026-07-17), the same day as the Constitution audit that first
named "Company → Branch → Terminal" as a gap. **No route, controller, or
UI was ever built for either.** `list_branches/1` and `list_terminals/1`
are scoped by `operator_id`, not `organisation_id` — inconsistent with
every other entity Phase 1 onward scopes by organisation, and with no
`with_organisation_access`-style guard at all, since no controller ever
called them.

Every phase checkpoint since — Phase 1 through the Phase 5 checkpoint
written 2026-08-14 — states "no Company→Branch→Terminal hierarchy exists"
or "still open." That statement was **false** for the entire period; the
correct statement was "exists at the schema/context layer, unreachable
by any user, not tenant-scoped." This was caught only by reading
`lib/fleet_mint/transport/fleet/` directly while writing this document,
not by trusting prior checkpoint prose. It is the concrete argument for
why this document's own rule (§ top of file) matters: a checkpoint that
isn't re-verified against running code becomes fiction the moment reality
moves past it.

---

## 2. Target Architecture — Constitution Domains Mapped to Code

The FleetMint Constitution (Working Draft v1.0) names 14 platform domains
(Chapters VI–XIX). Mapped here against what actually exists, not what the
Constitution envisions in full — several of the Constitution's own
chapters explicitly flag themselves as incomplete (noted below).

| Domain (Ch.) | Constitution's stated scope | Current FleetMint implementation |
|---|---|---|
| Identity (VI) | Trust, auth, authorization across the ecosystem | **Built.** `Identity` context, Guardian JWT, RBAC, org-scoping plug |
| Mobility (VII) | Planning/operating passenger transport | **Built.** `Transport.{Fleet,Routes,Trips,Ticketing,Boarding}` |
| Logistics (VIII) | Cargo, courier, warehousing, distribution | **Partially built.** `Cargo` covers freight client/order/trip/invoice; courier and warehousing are not represented at all |
| Fleet (IX) | Full lifecycle of operational assets | **Built**, with one dormant piece: Branch/Terminal (§1.9) |
| Finance (X) | Revenue, payments, obligations | **Partially built.** Cash collection/expenditure/reconciliation exist; broader "obligations management" is not a distinct capability |
| Accounting (XI) | Accurate, auditable financial records | **Deliberately scoped down.** Single-entry ledger, not double-entry/chart-of-accounts. The Constitution's own draft text (Part II close-out commentary) states plainly that the Accounting chapter "does not yet represent everything... a serious accountant, finance manager, payroll officer, auditor or CFO would expect" and calls for a full GL/AR/AP/cash-banking/asset-accounting model. This is a Constitution-acknowledged gap, not just a code gap. |
| Compliance (XII) | Legal/regulatory/contractual governance | **Not built as a domain.** `AuditLog` provides a trace; no compliance-specific capability exists |
| Localization (XIII) | Multi-region/currency/language support | **Not built.** ZMW is hardcoded; no i18n |
| HR (XIV) | Full workforce lifecycle | **Minimal.** `HR` context has only `Driver`. The Constitution's own draft text explicitly says HR "cannot remain a small supporting chapter" and lists a full People/Payroll/Workforce capability table (recruitment, payroll, statutory compliance, leave, performance, driver-licence compliance, etc.) as required — a Constitution-acknowledged gap, largest of the set |
| Customer (XV) | Relationship management | **Not built.** `Complaint` is the closest artefact; no CRM-style capability |
| Analytics (XVI) | Turning data into decisions | **Not built** beyond basic dashboard counts (`Finance.list_recent_reports/1`, `Fleet.count_buses/0`-style aggregates) |
| Artificial Intelligence (XVII) | Responsible AI-assisted decisioning | **Not built.** No AI capability anywhere in the codebase |
| Developer (XVIII) | Engineering discipline, docs, extensibility | **Partially built**, at the process level: CI, checkpoint discipline, this document. No developer-facing API/SDK surface, no ADR log, no context map/architecture-diagram artefacts beyond this document |
| Administration (XIX) | Governance/configuration/oversight | **Built.** `Administration` context, `platform_admin`/`tenant_admin` split, org-scoped audit querying (query-level; no route exposes it to tenant admins yet) |

Note: the Constitution's own Part III (Chapters XX+ — Security and Privacy
Governance onward) is announced but **not yet written** — the Constitution
itself is a working draft that stops after completing Part II (Platform
Architecture, Ch. VI–XIX).

---

## 3. Architecture Decision Queue

Unresolved questions, named explicitly as decisions to make — not
resolved here, and not assumed away by silence elsewhere.

1. ~~**Branch/Terminal fate.**~~ **Resolved 2026-08-15: retain, design
   properly, do not shelve.** Decision (Kello Sam): the target architecture
   clearly benefits from a proper organisational hierarchy — bus operators,
   depots/stations, school transport bases, logistics hubs, and government
   departments all need it. The model must be defined precisely before
   implementation resumes, not built vaguely. Defined model, recorded here
   as the approved near-term architecture (§ rule at top of document —
   this is *approved direction*, not yet *as-built fact* until Stage B
   ships it):

   - **Company (`Identity.Organisation`)** — unchanged from Phase 1. The
     tenant root and the only hard security/isolation boundary. Every
     Branch and Terminal traces to exactly one Organisation.
   - **Branch** — a physical operating location *within* one Organisation:
     a depot, a bus station's home base, a logistics hub, a district
     transport office. An operational subdivision, not a security boundary
     of its own.
     **Change required:** re-parent from `belongs_to :operator` to
     `belongs_to :organisation`. As built (commit `afee844`), a Branch can
     only exist for an Organisation that also has an Operator
     (passenger-transport) profile — but the examples motivating this
     feature (logistics hubs, government departments, school transport
     bases) are exactly the kind of Organisation the Constitution and
     Phase 1 both established may have **no** Operator profile at all.
     Branch inherited the identical defect Phase 1 already corrected
     Operator itself out of (see `docs/phase1_tenancy_checkpoint.md`,
     "first pass elevated Operator directly to tenant root... corrected").
   - **Terminal** — a specific service point within one Branch: a boarding
     point, a loading dock, a collection counter. Always `belongs_to
     :branch` (required) — cannot exist independently of a Branch.
     **Change required:** drop the redundant direct `belongs_to :operator`
     on Terminal. Tenant derivation should go through `terminal → branch →
     organisation` (one hop through Branch) — matching the established
     rule from Phase 1: "if a table's tenant is one hop away via an
     association, join through it rather than denormalizing a redundant
     column."
   - **Which records scope to each level:**
     - *Organisation* — the security boundary. Every table's tenant-
       isolation check stops here (unchanged).
     - *Branch* — an operational grouping, not an access-control boundary.
       Candidates to carry an optional `branch_id`: `Driver` (home branch
       — the Constitution's own HR chapter draft already names "companies,
       branches, departments" as required HR structure), `Vehicle`/`Bus`
       (home depot).
     - *Terminal* — the most granular level. Candidates to carry a
       `terminal_id`: `Booking` (pickup terminal — schema already has
       `bookings.terminal_id`, unused since 2026-07-17), `Schedule`
       (origin/destination terminal, not yet modelled), freight
       `Order`/`Trip` (collection/delivery point — directly relevant to
       the "logistics hub" use case named above, not yet modelled).
   - **Access control:** once re-parented, `get_branch!/1`/`get_terminal!/1`
     need the same `with_organisation_access`-style guard every other
     Phase 1+ entity has — currently neither has any, since no controller
     ever called them.

   **Not decided here:** which of Driver/Vehicle/Booking/Schedule/Order
   actually gets wired to `branch_id`/`terminal_id` first — that's Stage
   B's implementation-slice question (§4), informed by what the named
   pilot organisation (below) actually needs.
2. **Logistics scope.** Is `Cargo` (freight only) the intended full scope
   of the Mobility/Logistics split, or does the Constitution's broader
   vision (courier, warehousing) belong on the roadmap at all for a
   transport-operator customer base?
3. **Accounting depth.** Single-entry ledger is a deliberate, documented
   choice (2026-07-05). The Constitution's own draft wants a full
   GL/AR/AP model. When (if ever) does FleetMint's actual customer base
   need double-entry accounting, versus staying single-entry indefinitely?
4. **HR depth.** `Driver` alone, versus the Constitution's full
   People/Payroll/Workforce vision. This is the largest named gap in the
   Constitution's own text — worth an explicit scope decision rather than
   incremental drift.
5. **Sequencing of the five not-started domains** (Compliance, Localization,
   Customer, Analytics, AI) — none has begun. Which, if any, actually
   blocks a real pilot versus being genuinely future work?
6. **`routes` cross-tenant sharing.** Deliberately left unscoped at the
   model level since Phase 1 (interline/codeshare, Constitution Article
   VI.5) — still a deliberate exception, not a gap, but worth re-confirming
   it's still wanted before a pilot exposes it externally.
7. **Multi-driver/relief-crew trip assignments.** Trip currently has simple
   nullable single-value overrides; a `trip_crew_assignments` many-to-many
   model was named and deferred at Phase 2b.
8. ~~**`AuthController` layout.**~~ **Resolved 2026-08-15.** Verified and
   fixed: `/login`, `/register`, `/password-reset`, `/password-reset/:token`,
   and `/login/verify` all had the same missing `:public`-layout issue
   `PageController` had — each rendered wrapped in the internal admin
   sidebar. Fixed by scoping the `:public` layout to `AuthController` (whole
   controller — every action is pre-auth) and `PasswordResetController`
   (whole controller — same reason), and to just `TwoFactorController`'s
   `verify`/`confirm` actions (its `setup`/`enable`/`disable` actions are
   authenticated `/settings/2fa` pages and correctly keep the `:app`
   sidebar). Verified empirically per-route, not assumed from the pattern.
9. ~~**Pilot organisation.**~~ **Resolved 2026-08-15: Mazhandu Family Bus
   Services** (`operators.id = 7`, `organisation_id = 35`, slug
   `mazhandu`) is designated the FleetMint pilot organisation.

   Instruction was to pick whichever existing tenant has "the richest
   realistic data and most complete operational setup," with Jordan and
   Likili named as candidate front-runners. Queried the dev database
   directly (`fleet_mint_dev`) rather than guessing: **neither Jordan nor
   Likili is actually the richest.** Every one of the 28 seeded operators
   is thin on real operational data — zero buses, vehicles, drivers,
   bookings, cashing reports, or staff for all but one (Power Tools, 4
   staff, otherwise empty) — the seed data models route/schedule structure
   only, not full operational history. On the one dimension that does
   differ (schedule count and route diversity) plus profile completeness
   (real `contact_email`, a specific founding-year tagline vs. a generic
   one), **Mazhandu (12 schedules, 9 distinct routes, tagline "Zambia's
   Most Trusted Long-Distance Bus", real contact email) and CR Carriers
   (11 schedules, 10 distinct routes, tagline "Reliable Transport Since
   1972", real contact email) are both meaningfully ahead of Jordan (5
   schedules) and Likili (4 schedules)**, which have generic taglines and
   no contact email on file. Mazhandu is designated over CR Carriers by
   the narrowest margin (one more schedule); either would have been
   defensible.

   **Caveat, stated plainly:** this is a designation of *which name* the
   pilot will use, not evidence that Mazhandu already has real pilot-grade
   data — it doesn't, and neither does anything else in the dev database.
   The richness this decision was supposed to select for will come from
   actually running the pilot, not from which seed rows happened to exist
   first. The §3.17 pilot definition (scope, dates, data rules, success
   measures, exit conditions — still not written, see Stage A) is what
   turns this designation into an actual controlled pilot.

---

## 4. Controlled Implementation Roadmap

Per this document's own rule: only the next stage is specified in detail.
Later stages get objectives and dependencies, not invented schemas.

### Stage A — Close the pilot-readiness gate — CLOSED 2026-08-15

Directly targeted MIW-EIB-001 §3.16 (MVP governance) and §3.17 (pilot
definition):

- ~~Resolve Decision Queue item 1 (Branch/Terminal).~~ Done — retain,
  design properly; model recorded in item 1 above.
- ~~Resolve Decision Queue item 9 (name a pilot organisation).~~ Done —
  Mazhandu Family Bus Services designated; see item 9 above.
- ~~Verify Decision Queue item 8 (AuthController layout).~~ Done
  2026-08-15.
- **Still open, now unblocked rather than closed:** the §3.17 pilot
  definition itself (scope, dates, data rules, support arrangements,
  training, success measures, known limitations, incident procedures,
  feedback process, exit conditions) — a pilot organisation is named, but
  the pilot definition document doesn't exist yet. This is the one Stage A
  deliverable that didn't get produced in this pass and should be written
  as its own short artefact before a pilot is actually authorised per
  §3.9's "Authorise pilot" gate.

### Stage B — Branch/Terminal implementation — CLOSED 2026-08-15

All six steps shipped in one pass. Full evidence:
`docs/stage_b_branch_terminal_checkpoint.md`.

1. ~~Migration: re-parent `branches.operator_id` → `branches.organisation_id`.~~
   Done — `20260815100001_reparent_branches_to_organisation.exs`. Confirmed
   `branches`/`terminals` both had 0 rows in `fleet_mint_dev` before writing
   it, so this was a straight swap, not a data migration.
2. ~~Migration: drop `terminals.operator_id`.~~ Done —
   `20260815100002_drop_terminals_operator_id.exs`. Terminal now derives
   tenant through `branch → organisation` only.
3. ~~Add `with_organisation_access`-style guards.~~ Done —
   `Fleet.list_branches/1`/`list_terminals/1` accept `:all` or a real
   `organisation_id` (same `maybe_filter_*_organisation/2` pattern as
   `Bus`); `get_terminal!/1` preloads `:branch` so controllers can check
   `terminal.branch.organisation_id`.
4. ~~Build `BranchController`/`TerminalController`.~~ Done — full CRUD,
   HTML views, routes under the manager+ scope, 17 new tenant-isolation
   tests across both controllers.
5. ~~Wire `Booking.terminal_id` end-to-end.~~ Done — a "Pickup Terminal"
   select on the booking creation form, scoped to the caller's own
   organisation, an org-scoping guard on create (`terminal_allowed?/2`),
   and display on the booking show page. 2 new tests. Booking's edit form
   is a pre-existing stub ("under construction") — untouched, out of
   scope.
6. ~~Checkpoint this slice.~~ Done —
   `docs/stage_b_branch_terminal_checkpoint.md`. Full suite: 261 tests, 0
   failures. Migrations rehearsed up/down/up clean. Also fixed one real
   pre-existing bug surfaced while testing this (unrelated to
   Branch/Terminal itself): `get_booking!/1` never preloaded
   `schedule.route`, which `booking_html/show.html.heex` reads directly —
   would have crashed any real booking's show page; no prior test
   exercised that route.

Driver/Vehicle branch-assignment and Schedule/Order terminal-assignment
(named as candidates in Decision Queue item 1) remain explicitly **not**
built — each is its own future decision once a real pilot-org need for
them surfaces.

### Stage C — not yet designed

Per this document's own rule, only the next stage is specified in detail
once its dependency closes. Domains not touched by Stage B (Accounting
depth, HR depth, Logistics scope, Compliance, Localization, Customer,
Analytics, AI) remain named-but-undesigned until their own
architecture-decision gate is reached.

---

*This document should be re-verified against running code — not prior
checkpoints — before being trusted as current. §1.9 is the reason why.*
