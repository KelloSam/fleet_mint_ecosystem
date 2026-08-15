# FleetMint Pilot Definition & Authorization Plan

**Document Code:** FMT-PILOT-001
**Governing document:** `docs/PLATFORM_ARCHITECTURE_ROADMAP.md` (FMT-PAIR-001)
remains the controlling architecture document — this satisfies the §3.17
pilot-definition requirement that document's Stage A closeout named as
still open, and does not supersede it on any architecture question.
**Status:** Draft — sections marked **OPEN** below require a Miway
Technology / pilot-organisation decision before this document can be
approved and the pilot authorised. Do not treat an OPEN item as decided
by omission.

> Per this document's own governing principle (mirrored from
> `PLATFORM_ARCHITECTURE_ROADMAP.md`): this document shall describe what
> is verified true today as fact, and what remains an open business
> decision as explicitly open — never the other way around.

---

## 0. How this document was built

Written directly against `PLATFORM_ARCHITECTURE_ROADMAP.md` §1 (as-built
architecture, verified 2026-08-15) and the Stage A/B decision record, not
against the Constitution's full vision or assumed future capability. Where
a fact could be checked against running code or the live dev database
rather than recalled, it was — the pilot-organisation naming below is a
direct example: a routine migration rehearsal during Stage B wiped the dev
database's seed data on 2026-08-15, which meant the "12 schedules, 9
routes" evidence Stage A cited for Mazhandu no longer existed to
re-verify. Rather than silently reconstructing it, that incident is
recorded plainly (see `PLATFORM_ARCHITECTURE_ROADMAP.md`'s new
"Development environment reproducibility" principle and
`priv/repo/seeds.exs`'s header), and this document treats Stage A's naming
decision as authoritative *as a decision*, independent of whether its
supporting seed rows still exist in any particular developer's database.

No item below invents a pilot organisation, date, scope boundary, or
success threshold that wasn't already decided (Stage A) or directly
derivable from verified implemented capability. Every OPEN item is a real,
named business decision, not a placeholder.

---

## 1. Pilot organisation

**Mazhandu Family Bus Services** (`operators.slug = "mazhandu"`), per
`PLATFORM_ARCHITECTURE_ROADMAP.md` §3, Architecture Decision Queue item 9,
resolved and closed 2026-08-15 (commit `6ed7564`). Not reopened by this
document — see §0 above for why the underlying dev-DB evidence no longer
being queryable doesn't change that a decision was made.

**What Stage A's decision was actually evidence for, precisely stated**:
which *tenant it should route/route-fictional demonstration seed data
under* was never real evidence of Mazhandu's actual operational
readiness — Stage A's own text said this outright ("this is a designation
of *which name* the pilot will use, not evidence that Mazhandu already has
real pilot-grade data — it doesn't, and neither does anything else in the
dev database"). Nothing about the seed-data wipe changes that
finding; if anything it removes a temptation to mistake old seed rows for
real evidence.

**OPEN — requires Mazhandu's own confirmation, not Miway's alone**: has
Mazhandu Family Bus Services actually agreed to participate as the pilot
organisation? Stage A named them from Miway's own side (richest available
signal among existing `operators` rows); nothing in this repository or its
history records Mazhandu's own consent, a contact person, or a signed
pilot agreement. **This is the single most load-bearing open item in this
document** — every other OPEN item downstream (real dates, real staff
accounts, real operational data) depends on this being resolved first.

---

## 2. Pilot scope — what is genuinely implemented and pilotable today

Derived directly from `PLATFORM_ARCHITECTURE_ROADMAP.md` §1 and §2, not
from the Constitution's full vision. **In scope** (built, tested, and
tenant-scoped):

- **Fleet setup**: Vehicles/Buses, Drivers, Branches, Terminals
  (Stage B — new, and consequently the least battle-tested capability
  named in this scope; see §9's entry criteria).
- **Passenger transport core**: Route → Schedule → Booking → Ticket (QR),
  with seat-map validation and a pickup-terminal selection (Stage B wired
  `Booking.terminal_id` end-to-end).
- **Trip model & boarding**: the Route→Schedule→Trip GTFS-style model,
  boarding/checkpoint validation (`Transport.Boarding`).
- **Cash reconciliation**: CashingReport → Expenditure → weekly Report,
  with the trip-matching reconciliation UI
  (`docs/phase2_trip_model_checkpoint.md`).
- **Administration**: `platform_admin`/`tenant_admin`/`manager`/`cashier`
  roles, org-scoped audit logging (`Administration.log/2`), operation
  logs, passenger complaints.
- **Freight** (`Cargo`): client/order/trip/invoice, **only if** Mazhandu
  actually operates a freight side-business — unconfirmed, see §3's OPEN
  item. If not, this stays untouched dev-only capability for this pilot.

**Explicitly out of scope** (not built, or deliberately scoped down — not
a pilot-readiness gap, a standing architecture decision):

- Double-entry accounting/GL/AR/AP (single-entry ledger is deliberate,
  Decision Queue item 3).
- Full HR/payroll/workforce beyond `Driver` records (Decision Queue item
  4 — Constitution-acknowledged gap).
- Compliance, Localization, Customer/CRM, Analytics beyond basic counts,
  AI — none built (§2 domain table).
- Courier/warehousing logistics beyond freight client/order/trip/invoice
  (Decision Queue item 2).
- A dedicated notification/delivery system — `/api/notifications` exists
  as a basic booking-status JSON endpoint, not a notification/delivery
  platform.
- Multi-driver/relief-crew trip assignments (Decision Queue item 7).

**OPEN**: does Mazhandu's real business actually need anything on the
"out of scope" list to run even a minimal pilot (e.g., do they run
freight)? Nobody has asked them yet (see §1's OPEN item) — this section
can only be finalised after that conversation.

---

## 3. Users and roles

Implemented roles (`FleetMint.Identity.User.role`): `tenant_admin`,
`manager`, `cashier`. (`platform_admin` is Miway's own staff, not a pilot
role; a fourth string value, `operator`, exists in the schema's valid-role
list but has no distinct permission behaviour anywhere in the codebase
today — worth naming honestly rather than assuming it means something it
doesn't yet.)

**OPEN**: which real Mazhandu staff member holds each role, and how many
of each. This cannot be answered from this repository — it requires
Mazhandu's own organisational structure, which requires §1's OPEN item to
resolve first.

---

## 4. Real operational workflows

The pilot exercises exactly the workflow chain named in §2's in-scope
list: **vehicle/driver setup → route/schedule setup → booking/ticket
issuance → boarding/checkpoint validation → cash reconciliation
(CashingReport → Expenditure → weekly Report) → trip-matching
reconciliation.** Freight (client → order → trip → invoice) is
conditional on §2's OPEN item.

This section intentionally does not restate §2's detail — see it instead
of duplicating it.

---

## 5. Pilot dates and duration — OPEN

No dates are proposed here. Setting them requires, at minimum: §1's
organisation-agreement OPEN item resolved, and §9's entry criteria
substantially met. A reasonable shape (not a schedule) once those exist:
a preparation/onboarding period (real data entry + validation, see the
onboarding process in §6), a controlled launch, a defined observation
window, and a review point — mirroring the phase/stage discipline this
codebase already uses everywhere else, not a novel process.

---

## 6. Safety, data boundaries, and pilot onboarding process

**Data boundary principle** (per the reproducibility principle just added
to `PLATFORM_ARCHITECTURE_ROADMAP.md`): development seed data
(`priv/repo/seeds.exs`) and real pilot data are two separate categories
that must never mix. Mazhandu's real staff information, vehicle registry,
route/fare data, and financial records must never be committed to this
repository as seed data, fixtures, or example content in this or any
other document.

**Pilot onboarding process** (the controlled path from "organisation
named" to "real data flowing through FleetMint," replacing the
`mix run priv/repo/seeds.exs` dev shortcut for anything pilot-related):

1. Organisation selected (done — Stage A, §1 above).
2. Pilot agreement/authorisation (OPEN — §1).
3. Tenant created: real `Organisation` + `Operator` row for Mazhandu,
   created through `Fleet.create_operator/1` (the same context function
   this codebase already uses for every operator onboarding — no new
   code needed).
4. Administrator account established for Mazhandu's own nominated
   `tenant_admin`.
5. Organisational structure configured: real Branch/Terminal records
   (Stage B), reflecting Mazhandu's actual depot/boarding-point structure
   — not invented ahead of §1/§3's OPEN items resolving.
6. Operational master data imported or entered: real vehicles, drivers,
   routes, schedules. Whether this is manual entry through the built UI
   or a one-time import script is **OPEN** — depends on how much
   structured data Mazhandu can actually hand over versus how much needs
   entering by hand.
7. Validation: a dry run through the full workflow chain (§4) with no
   real passengers/money, checked against §9's entry criteria.
8. Pilot readiness review (§11's evidence register, reviewed against
   §9/§10).
9. Go-live, per whatever dates §5 eventually resolves to.

**Production infrastructure — OPEN, currently unresolved, and worth
naming plainly rather than assuming it's someone else's problem**: this
repository has release-ready `config/runtime.exs` (reads `DATABASE_URL`
and equivalent env vars, matching a standard `mix release`), and a real
SMTP mailer is already configured for production (Phase 0, Gmail SMTP —
not a pilot-blocking gap). But there is no Dockerfile, no PaaS
configuration (Fly.io, Render, etc.), and no chosen hosting target
anywhere in this repository — meaning *where* a pilot deployment would
actually run, who holds its credentials, and what its backup/restore
procedure is are all genuinely undecided. This blocks go-live regardless
of how §1/§5 resolve.

---

## 7. Support and incident procedure

**OPEN**: no named support/incident-response contact or escalation path
exists yet for a live pilot (this differs from engineering-time defect
tracking, which this codebase already does well — see §11). Structure
proposed, not decided: first responder → escalation → resolution logged
in the pilot evidence register (§11), same "record what happened" pattern
this codebase already applies to every domain (append-only audit/ledger
entries, never silent edits). Who actually holds "first responder" for a
live pilot is a real staffing decision, not something this document can
assign.

---

## 8. Entry criteria — before the pilot may go live

Checkable against real evidence, split by what's already true versus what
still needs to happen:

**Already satisfied** (verified 2026-08-15, this session):
- Full test suite green: 261 tests, 0 failures.
- `mix format --check-formatted` clean.
- CI green on every push to `master` (format, compile, migrate, test).
- Production-grade mailer configured (Gmail SMTP, Phase 0).
- Migrations rehearsed up/down/up clean, including Stage B's.

**Not yet satisfied — genuine gaps, not invented ones:**
- §1: pilot organisation's own agreement to participate.
- §3: real Mazhandu role assignments.
- §6: production hosting target chosen and provisioned, including a
  verified backup/restore procedure.
- §7: a named support/incident contact for the live pilot.
- Stage B (Branch/Terminal) has automated test coverage
  (`docs/stage_b_branch_terminal_checkpoint.md`) but, unlike Phases 1–5,
  has not yet been exercised through a real multi-branch/terminal
  scenario with real data — worth a deliberate dry run (§6, step 7)
  rather than assuming test coverage alone proves operational readiness.
- No load/performance testing exists anywhere in this codebase's history
  — worth naming as a real unknown for a pilot involving real passenger
  traffic, not assuming Rails-scale traffic makes it a non-issue.

---

## 9. Success measures — categories defined, thresholds OPEN

Measurable categories, matching what's actually implemented (not vague
"users liked it" language):

- **Workflow completion rate**: % of booking→ticket, cashing-report
  reconciliation, and (if in scope) freight order→invoice sequences
  completed without support intervention.
- **Reconciliation accuracy**: cash-report trip-matching auto-match rate
  and manual-match correction rate, compared against Mazhandu's own prior
  manual process (baseline unknown — needs Mazhandu's input).
- **Tenant isolation**: zero cross-tenant access incidents (a hard
  requirement, not a target to trend toward — this codebase already
  treats this as an architectural invariant, not a KPI).
- **Defect severity distribution**: using the same Critical/High/Medium
  severity language this project already uses in its checkpoints, tracked
  in §11's evidence register.
- **Reliability**: uptime/availability over the observation window —
  meaningless without §6's hosting decision existing first.
- **User acceptance**: qualitative feedback from Mazhandu's own staff,
  collected structurally (not anecdotally) through the pilot evidence
  register.

**OPEN**: the actual pass/fail thresholds for each category (e.g., what
completion-rate percentage counts as success) are a joint Miway/Mazhandu
business decision this document does not have standing to invent.

---

## 10. Exit criteria

Framework, not numbers (numbers depend on §9's OPEN thresholds):

- **Success → extend/formalise**: thresholds met, no unresolved
  Critical-severity defects, Mazhandu confirms intent to continue.
- **Partial success → extend pilot window**: some thresholds unmet but
  trending toward them, no tenant-isolation or data-integrity incidents.
- **Suspend**: a Critical-severity defect (financial-record integrity,
  cross-tenant access, data loss) found during the pilot — matches this
  codebase's own standing "no deployment until CI evidence exists"-style
  discipline (see Steward7's parallel gate, same governing principle at
  Miway Technology level, not copied verbatim here).
- **Return to engineering**: pilot reveals a genuine scope gap (§2's OPEN
  item resolving "yes, freight is needed" would be an example) requiring
  real build work before a pilot can meaningfully continue.

---

## 11. Pilot evidence register

To be created as `docs/pilot/PILOT_EVIDENCE_LOG.md` once the pilot
actually begins (not fabricated ahead of real events) — same "record what
happened, don't invent it" discipline as every phase/stage checkpoint in
this repository. Tracks: defects found (severity-tagged, same convention
as this project's own checkpoints), operational observations, user
feedback, and the §9 measurements as they're actually collected.

---

## 12. Authorisation and sign-off

| Responsibility | Assignment |
| --------------- | ---------- |
| Document author | Claude (Sonnet 5), this session, 2026-08-15 |
| Reviewer | **OPEN — not yet assigned** |
| Pilot authorisation authority | **OPEN — presumably Kello Sam as Miway Technology Project Owner, per this project's standing pattern elsewhere, but not yet confirmed for FleetMint specifically** |
| Mazhandu-side authority | **OPEN — no named contact exists yet (§1)** |
| Approval status | **Not approved. Draft, pending the OPEN items above.** |

This document does not authorise a pilot by existing — it defines what a
pilot needs before it can be authorised. Per §3.9 of the parent Blueprint
(MIW-EIB-001), formal "Authorise pilot" remains a distinct, later step.
