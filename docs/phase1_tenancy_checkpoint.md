# Phase 1 Checkpoint — Tenant Boundary (Organisation Scoping)

**Status:** Functionally complete, subject to documented pre-existing test debt.
**Commit range:** `c9357d5` (end of Phase 0) → `80d1a87` (Phase 1 complete)
**Test command used throughout:** `mix test` (Postgres test DB, `MIX_ENV=test`)
**Checkpoint date:** 2026-07-18

This document exists so the 33 pre-existing test failures referenced below
cannot become a vague, undocumented excuse in later phases. Every claim here
was verified by an actual command run, not asserted from memory.

---

## 1. Domains covered

| Domain | Tables | Controllers |
|---|---|---|
| Transport | `schedules`, `bookings` | `ScheduleController`, `BookingController` |
| Fleet | `vehicles`, `buses` | `VehicleController`, `BusController` |
| HR | `drivers` | `DriverController` |
| Finance | `cashing_reports`, `expenditures` | `CashingReportController`, `ExpenditureController` |
| Cargo | `freight_clients`, `freight_orders`, `freight_trips`, `freight_invoices` | `FreightClientController`, `FreightOrderController`, `FreightTripController`, `FreightInvoiceController` |

**Deliberately out of scope, not overlooked:**
- `routes` — stays unscoped at the model level. It's `many_to_many` with `operators` for interline/codeshare service; Constitution Article VI.5 treats cross-tenant route sharing as a governed exception, not the default case. Scoping it as if every route belongs to exactly one tenant would be wrong, not incomplete.
- `public_booking_controller.ex` — the cross-operator public booking site passengers use to browse all companies. A different, correct concern from staff-side tenant isolation; intentionally untouched.
- `trip_milestones` — no independent access guard; only ever reached through its parent Trip's own guarded actions (`FreightTripController.add_milestone/2`), so it inherits that guard rather than needing its own.

---

## 2. Migrations introduced (in application order)

1. `20260717202742_create_branches.exs`
2. `20260717202748_create_terminals.exs`
3. `20260717202754_add_operator_id_to_users.exs` — superseded by #6 below; kept in history as applied.
4. `20260717202801_add_terminal_id_to_bookings.exs`
5. `20260718001751_create_organisations.exs`
6. `20260718001756_add_organisation_id_to_operators.exs` — backfills one Organisation per pre-existing Operator, matched by slug.
7. `20260718001800_replace_operator_id_with_organisation_id_on_users.exs` — drops `users.operator_id` (added in #3, unused — both existing accounts were still `nil`), adds `users.organisation_id`.
8. `20260718003250_add_organisation_id_to_vehicles.exs`
9. `20260718003256_add_organisation_id_to_buses.exs`
10. `20260718003301_add_organisation_id_to_drivers.exs`
11. `20260718003306_add_organisation_id_to_freight_clients.exs`

## 3. Schemas — organisation_id ownership

**Own the column directly** (nullable, so an unassigned record defaults to platform-only visibility — fail closed):
`Operator` (NOT NULL — every Operator has exactly one Organisation), `User`, `Vehicle`, `Bus`, `Driver`, `Client` (Cargo).

**Derive it through an association** (no redundant column):
- `Schedule` → `operator_id` → `Operator.organisation_id`
- `Booking` → `schedule_id` → `Schedule` → `operator_id` → `Operator.organisation_id`
- `CashingReport` → `bus_id` → `Bus.organisation_id`
- `Expenditure` → `cashing_report_id` → `CashingReport` → `bus_id` → `Bus.organisation_id`
- `Order` (Cargo) → `client_id` → `Client.organisation_id`
- `Trip` (Cargo) → `vehicle_id` → `Vehicle.organisation_id`
- `Invoice` (Cargo) → `client_id` → `Client.organisation_id`

## 4. Server-side scoping functions

`Identity.Authorization.platform_level?/1`, `Identity.Authorization.can_access_organisation?/2` — canonical checks, unit-tested directly.

`FleetMintWeb.Plugs.TenantScopePlug` — runs immediately after `AuthPlug`, assigns `conn.assigns.organisation_scope` (`:all` for platform-level staff, an `organisation_id` for tenant staff).

Context list functions accepting an `:organisation_id` (`:all`/`nil`/id) filter option:
`Trips.list_schedules/1`, `Ticketing.list_bookings/1`, `Ticketing.list_bookings_paginated/2`, `Fleet.list_vehicles/1`, `Fleet.list_buses/1`, `Fleet.list_buses_by_status/2`, `Fleet.list_trucks/1`, `Fleet.list_buses_v2/1`, `HR.list_drivers/1`, `Finance.list_cashing_reports/1`, `Finance.list_expenditures/1`, `Cargo.list_clients/1`, `Cargo.list_orders/1`, `Cargo.list_trips/1`, `Cargo.list_invoices/1`.

## 5. Cross-tenant protections (per controller, all 11)

`ScheduleController`, `BookingController`, `VehicleController`, `BusController`, `DriverController`, `CashingReportController`, `ExpenditureController`, `FreightClientController`, `FreightOrderController`, `FreightTripController`, `FreightInvoiceController` — each:

- **index/list** — filtered by `conn.assigns.organisation_scope`.
- **create** — the organisation (or, for join-derived resources, the parent record id) is forced server-side from the caller's own scope; a client-submitted value for a different organisation is silently overridden or rejected, never trusted.
- **show/edit/update/delete** — guarded by a `with_organisation_access`-style check; a request against another organisation's record redirects with a flash error instead of 403/404, matching the app's existing error-handling convention.

## 6. Tests added this phase (26 new, all passing)

| File | Tests | What it proves |
|---|---|---|
| `test/fleet_mint/identity/authorization_test.exs` | 4 | `platform_level?/1` and `can_access_organisation?/2` — both true and false branches, unit level |
| `test/fleet_mint/transport/trips_test.exs` | 2 | `list_schedules/1` organisation filter + `:all` bypass |
| `test/fleet_mint/transport/ticketing_test.exs` | 2 | `list_bookings/1` organisation filter + `:all` bypass |
| `test/fleet_mint/transport/fleet_test.exs` | 2 | `list_vehicles/1`, `list_buses/1` organisation filters |
| `test/fleet_mint/hr_test.exs` | 2 | `list_drivers/1` organisation filter + `:all` bypass |
| `test/fleet_mint/finance_test.exs` | 2 | `list_cashing_reports/1`, `list_expenditures/1` organisation filters (join-derived, 1- and 2-hop) |
| `test/fleet_mint/cargo_test.exs` | 4 | `list_clients/1`, `list_orders/1`, `list_trips/1`, `list_invoices/1` organisation filters |
| `test/fleet_mint_web/controllers/bus_controller_test.exs` | 8 | **Real authenticated HTTP requests** (via `log_in_user/2`, a genuine Guardian session token, not a shortcut): authorised view/index for a tenant user and a platform user; **prohibited** view, edit, update, and delete against another organisation's bus (update/delete confirmed to leave the row untouched); tampered `organisation_id` on create is overridden server-side |

**Honest gap:** the authenticated-HTTP-request pattern (`bus_controller_test.exs`) was proven on one representative controller, not replicated across all 11. The other 10 controllers' guards are exercised by the context-level list-filter tests plus the standalone `Authorization` unit tests, but not by a real HTTP request hitting their specific `with_organisation_access` branch. Extending the `log_in_user/2` pattern to the remaining controllers is mechanical repetition of what `bus_controller_test.exs` already establishes — not done here, named explicitly rather than left implicit.

## 7. The 33 pre-existing failures — exact list, verified by diff

Verified by checking out commit `c9357d5` (end of Phase 0, before any Phase 1 work) into an isolated git worktree with its own test database, running `mix test` there, and diffing the exact failing-test-name list against the current one on `80d1a87`. **The diff is empty — byte-for-byte identical set, not just a matching count.**

```
test cashing_reports create_cashing_report/1 with valid data creates a cashing_report (FleetMint.FinanceTest)
test cashing_reports get_cashing_report!/1 returns the cashing_report with given id (FleetMint.FinanceTest)
test cashing_reports list_cashing_reports/0 returns all cashing_reports (FleetMint.FinanceTest)
test cashing_reports update_cashing_report/2 with invalid data returns error changeset (FleetMint.FinanceTest)
test create cashing_report renders errors when submitted data is invalid (FleetMintWeb.CashingReportControllerTest)
test create cashing_report successfully creates a cashing report and redirects to show page (FleetMintWeb.CashingReportControllerTest)
test create expenditure redirects to show when data is valid (FleetMintWeb.ExpenditureControllerTest)
test create expenditure renders errors when data is invalid (FleetMintWeb.ExpenditureControllerTest)
test create report redirects to show when data is valid (FleetMintWeb.ReportControllerTest)
test create report renders errors when data is invalid (FleetMintWeb.ReportControllerTest)
test delete cashing_report successfully deletes a cashing report and redirects to index (FleetMintWeb.CashingReportControllerTest)
test delete expenditure deletes chosen expenditure (FleetMintWeb.ExpenditureControllerTest)
test delete report deletes chosen report (FleetMintWeb.ReportControllerTest)
test edit cashing_report renders form for editing an existing cashing report (FleetMintWeb.CashingReportControllerTest)
test edit expenditure renders form for editing chosen expenditure (FleetMintWeb.ExpenditureControllerTest)
test edit report renders form for editing chosen report (FleetMintWeb.ReportControllerTest)
test expenditures create_expenditure/1 with valid data creates a expenditure (FleetMint.FinanceTest)
test expenditures get_expenditure!/1 returns the expenditure with given id (FleetMint.FinanceTest)
test expenditures list_expenditures/0 returns all expenditures (FleetMint.FinanceTest)
test expenditures update_expenditure/2 with invalid data returns error changeset (FleetMint.FinanceTest)
test GET / (FleetMintWeb.PageControllerTest)
test index index displays the list page with all cashing reports (FleetMintWeb.CashingReportControllerTest)
test index lists all expenditures (FleetMintWeb.ExpenditureControllerTest)
test index lists all reports (FleetMintWeb.ReportControllerTest)
test new cashing_report renders the new cashing report form (FleetMintWeb.CashingReportControllerTest)
test new expenditure renders form (FleetMintWeb.ExpenditureControllerTest)
test new report renders form (FleetMintWeb.ReportControllerTest)
test update cashing_report renders errors when update data is invalid (FleetMintWeb.CashingReportControllerTest)
test update cashing_report successfully updates a cashing report with valid data (FleetMintWeb.CashingReportControllerTest)
test update expenditure redirects when data is valid (FleetMintWeb.ExpenditureControllerTest)
test update expenditure renders errors when data is invalid (FleetMintWeb.ExpenditureControllerTest)
test update report redirects when data is valid (FleetMintWeb.ReportControllerTest)
test update report renders errors when data is invalid (FleetMintWeb.ReportControllerTest)
```

**Why these fail, established before this phase touched anything:** two independent causes, neither related to organisation scoping —
1. `CashingReportControllerTest`, `ExpenditureControllerTest`, `ReportControllerTest` — these tests never log a user in before hitting routes that require authentication (added after these tests were written); every request 302s to `/login`. `bus_controller_test.exs` in this phase demonstrates the fix (`log_in_user/2`); it has not been back-applied to these three files.
2. `FleetMint.FinanceTest`'s `cashing_reports`/`expenditures` blocks — a pre-existing `Decimal` precision mismatch (`"120.5"` vs. stored `"120.50"`) and one test missing a required `report_date` field, both predating this phase.
3. `PageControllerTest` — asserts landing-page copy that doesn't match the current template; a content drift, not a logic bug.

## 8. Verification commands (reproducible)

```bash
# Full current suite
mix test

# Exact current failure names
mix test 2>&1 | grep -E "^\s*[0-9]+\) test" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]*//' | sort

# Baseline reproduction (what was run to build section 7):
git worktree add /tmp/fleet_mint_phase0_baseline c9357d5
cd /tmp/fleet_mint_phase0_baseline
MIX_TEST_PARTITION=phase0baseline MIX_ENV=test mix ecto.create
MIX_TEST_PARTITION=phase0baseline MIX_ENV=test mix ecto.migrate
MIX_TEST_PARTITION=phase0baseline MIX_ENV=test mix test 2>&1 | grep -E "^\s*[0-9]+\) test" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]*//' | sort > baseline.txt
diff baseline.txt current.txt   # empty output = proof
```

## 9. Result, stated precisely

**127 tests: 94 passing, 33 known pre-existing failures (documented above, unrelated to organisation scoping), 0 new failures introduced by Phase 1.** This must not be described as "all tests pass" or "green" — it is *functionally complete, subject to documented pre-existing test debt* that existed before this phase and is now, for the first time, precisely enumerated and diff-verified rather than asserted.

---

**Commit representing Phase 1 completion: `80d1a87`**
