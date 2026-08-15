# Stage B Checkpoint: Branch/Terminal Implementation

Same evidence standard as the Phase 1–5 checkpoints. This is the platform's
first stage checkpointed under the new `docs/PLATFORM_ARCHITECTURE_ROADMAP.md`
staging scheme (Stage A/B/...) rather than the earlier "Phase N" language —
see that document's own Stage A closeout (commit `6ed7564`) for how the two
numbering schemes relate.

## 1. What this stage did

Stage A (closed 2026-08-15, commit `6ed7564`) resolved two governance
decisions: retain and properly design Branch/Terminal (don't shelve it), and
designate Mazhandu Family Bus Services as the pilot organisation. That
turned Stage B from a directional objective into the fully-specified,
6-step implementation slice recorded in the roadmap's own Stage B section.
All six steps shipped in this pass:

1. **Migration: re-parent `branches.operator_id` → `branches.organisation_id`**
   (`20260815100001_reparent_branches_to_organisation.exs`). Branch
   inherited the same tenant-root defect Phase 1 already corrected Operator
   itself out of — an Organisation may have no Operator profile at all
   (logistics hubs, government departments, school transport bases named in
   the roadmap's own item 1), so Branch must trace to Organisation directly.
   Verified `branches`/`terminals` both had 0 rows in `fleet_mint_dev`
   before writing this — a straight swap, not a data migration.
2. **Migration: drop `terminals.operator_id`**
   (`20260815100002_drop_terminals_operator_id.exs`) — redundant once
   Terminal derives tenant through `branch → organisation` (one hop through
   Branch), matching the Phase 1 rule already in force elsewhere in this
   codebase.
3. **Org-scoping guards**: `Fleet.list_branches/1` and `Fleet.list_terminals/1`
   both now accept `:all` (platform-level) or a real `organisation_id`,
   matching the existing `maybe_filter_bus_organisation/2` pattern exactly.
   `Terminal` has no direct organisation column, so `list_terminals/1` joins
   through `branch` — `get_terminal!/1` preloads `:branch` so controllers
   can read `terminal.branch.organisation_id` for the access check.
4. **`BranchController`/`TerminalController`**: full CRUD, HTML views
   (index/new/edit/show/form), routes under the manager+ scope
   (`resources "/branches"`, `resources "/terminals"`) — built against the
   exact `with_organisation_access`/`force_organisation_scope` pattern
   `BusController` established. `TerminalController` additionally validates
   the selected `branch_id` belongs to the caller's own organisation before
   create/update (`branch_allowed?/2`, same shape as `FuelLogController`'s
   `vehicle_allowed?/2`) — without this, a crafted POST could attach a
   terminal to another organisation's branch.
5. **Wired `Booking.terminal_id` end-to-end**: the column has existed since
   2026-07-17 but had no form field anywhere — dead in the UI. Added a
   "Pickup Terminal" select to the booking creation form
   (`booking_html/new.html.heex`), scoped to the caller's own organisation's
   terminals, and a `terminal_allowed?/2` guard in
   `BookingController.create/2` (same shape as the existing
   `schedule_allowed?/2` check) so a crafted POST can't attach a booking to
   another organisation's terminal. Terminal name now displays on the
   booking show page. Booking's `edit.html.heex` is a pre-existing stub
   ("This module is under construction") — out of scope, not touched.
6. **This checkpoint.**

## 2. A real pre-existing bug found and fixed while testing this

Writing an end-to-end test for terminal display (create a booking, then
view its show page) surfaced a latent bug unrelated to Branch/Terminal
itself: `Ticketing.get_booking!/1` preloaded `schedule: :operator` but not
`schedule: :route`, while `booking_html/show.html.heex` reads
`@booking.schedule.route.name` directly. No existing test exercised
`GET /bookings/:id` against a schedule with a route attached — the only
prior booking controller test covered `GET /bookings/new`. Fixed by
widening the preload to `schedule: [:operator, :route]`. This would have
crashed the show page for any real booking in production; worth flagging
that `/bookings/:id` apparently had no test coverage at all before this
pass.

## 3. Test evidence

- 4 new test files / additions: `branch_controller_test.exs` (8 tests),
  `terminal_controller_test.exs` (9 tests, including cross-org branch
  create rejection), 2 new tests appended to the existing
  `booking_controller_test.exs` (terminal wired end-to-end; cross-org
  terminal rejected). All follow the same tenant-isolation pattern
  established by `bus_controller_test.exs`.
- Full suite: **261 tests, 0 failures** (up from 259 before this stage;
  net +2 in `booking_controller_test.exs`, +17 in the two new files —
  the 259 baseline already reflects `mix test` passing clean per the
  Phase 5 checkpoint).
- `mix format --check-formatted`: clean (ran `mix format` once to absorb
  drift from the new files, reformatted 2 pre-existing files it touched
  incidentally: `booking_html/show.html.heex`, `booking_html/new.html.heex`
  — content unchanged, whitespace/wrapping only).
- `mix compile`: clean. Same 7 pre-existing `prompt` attribute warnings
  as every prior checkpoint (`cashing_report_html.ex`, `fuel_log_html.ex`
  ×2, `minibus_trip_html.ex` ×3, `vehicle_maintenance_html.ex`) — untouched,
  out of scope, CI doesn't run `--warnings-as-errors`.
- Migrations rehearsed up → down → up from the existing dev database
  (`fleet_mint_dev`), both directions clean, no errors.
- No Credo configured in this project (unlike Steward7) — nothing to run.

## 4. What is explicitly not built here

- **Driver/Vehicle branch-assignment, Schedule/Order terminal-assignment**
  — named as future candidates in the roadmap's Decision Queue item 1, not
  part of this slice by the roadmap's own explicit scoping.
- **Booking edit form** — pre-existing stub, untouched; adding the terminal
  field there is a natural follow-up once that form is actually built.
- **§3.17 pilot definition document** — still open per Stage A's own
  closeout note; blocks the pilot's formal authorisation (§3.9), not this
  implementation slice.
- **Cashier-facing terminal browsing** — `BranchController`/
  `TerminalController` routes are manager+ only, matching the roadmap's
  framing of Branch/Terminal as operational/admin setup, not a cashier
  workflow. Cashiers only see terminals through the booking form's
  dropdown, populated directly by `Fleet.list_terminals/1` in
  `BookingController`, not by navigating the new routes.

---

**Commit representing this checkpoint: recorded in the same commit as this
document.**
