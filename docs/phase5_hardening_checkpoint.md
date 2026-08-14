# Phase 5 Checkpoint: Org-Scoping Completion, Financial Audit Trail & CI

Same evidence standard as the Phase 1–4 checkpoints. Unlike Phases 1–4, this
phase's work (2026-08-11) landed as a run of commits without a written
checkpoint at the time — this document records it after the fact, plus the
test-suite remediation done alongside it to bring `mix test` back to 0
failures for the first time since Phase 1.

## 1. What this phase found and fixed

### 1.1 Org-scoping completion sweep

Phase 1 (see `docs/phase1_tenancy_checkpoint.md`) scoped the primary tenant
surface: schedules, bookings, vehicles, buses, drivers, cashing reports,
expenditures, freight clients/orders/trips/invoices. This sweep went back
over the rest of the app and closed every remaining cross-tenant gap found:

| Commit | Gap | Exposure before the fix |
|---|---|---|
| `c7ca4c5` | Fuel logs, vehicle maintenance, minibus trips, tickets | Any authenticated staff member could read/edit/delete any other organisation's fuel logs, maintenance records, and minibus trips; ticket show/validate had no owner check |
| `99d1085` | Weekly report edit/delete | Any manager could edit or delete any org's weekly report; deletion cascades (`on_delete: :delete_all`) to every cashing report and expenditure filed under it — a cross-tenant data-destruction path |
| `cd1cced` | Reconciliation aggregates | `/reconciliation` showed every tenant's minibus variance, intercity collections, and freight invoice aging with no filter |
| `59ec1aa` | PDF report downloads | `/pdf/daily`, `/pdf/expenditures` pulled every tenant's data; `/pdf/weekly/:id`, `/pdf/receipt/:id` generated a PDF for any report/cashing-report ID regardless of owning org |
| `1da7126` | `operation_logs`, `complaints` | Neither table had a tenant column at all — any staff member could see and edit every organisation's operation logs and passenger complaints (the latter carrying real passenger name/phone PII) |
| `92b9a8b` | `/api/notifications` | No org filter on the bookings query, plus a stale `"admin"` role check left over from the Phase 3 `platform_admin`/`tenant_admin` split — both new admin roles were actually locked out while `manager` still worked |
| `739da80` | Schedule/booking form dropdowns, public booking flow | New/edit forms leaked every org's operator and staff names into dropdowns (display-only, not a write path); the public booking flow trusted an operator slug and a schedule ID independently with no check they agreed, letting a crafted URL enumerate or book another operator's schedule |

`operation_logs` and `complaints` needed real schema migrations
(`organisation_id`, nullable, never client-settable), following the existing
`audit_logs` precedent. `complaints` — submitted through an unauthenticated
public form with no operator selector — is best-effort backfilled by
resolving the passenger-typed booking reference to `booking → schedule →
operator → organisation`; no match leaves it `nil` (platform-only visible),
never guessed into a tenant.

### 1.2 Financial audit trail and freight validation (`204fa40`)

- Expenditures and CashingReports previously had no record of who created,
  edited, or deleted them, and delete was a hard `Repo.delete` with zero
  trace — a cashier could pad or erase a financial record with nothing to
  point back to them. Both schemas gained `created_by_id`/`updated_by_id`
  (server-set only) and `archived_at` (soft delete — the row and its history
  survive, just hidden from normal listings/totals/reports), plus
  `Administration.log` entries on create/update/delete. Expenditure
  edit/update/delete is now manager+ only, so the cashier who logs an
  expense can't unilaterally edit or erase it.
- Freight: trip assignment is now validated against the order's client
  organisation and the vehicle's remaining payload capacity on every
  create/update path. Cancelling a trip releases its still-open orders back
  to `pending` instead of leaving them stuck on a dead trip.
- Fixed the user-creation form, which had no Organisation field at all —
  every non-`platform_admin` role requires one, so creating a manager,
  cashier, `tenant_admin`, or operator was silently failing validation.

### 1.3 CI and formatting (`c45a2b4`, `7522ca4`)

GitHub Actions now runs `mix format --check-formatted`, `mix compile`,
`mix ecto.create && mix ecto.migrate`, and `mix test` against a real
Postgres service container on every push/PR to `master`. `mix format` was
run across the whole codebase first so the new check-formatted step had a
clean baseline (whitespace/wrapping only, verified same 190 tests / 33
failures before and after).

## 2. Test-suite remediation (this session)

CI existing while the suite carried 33 known failures defeats CI as a gate,
so before treating this phase as closed, all 33 were individually
classified by root cause (not just re-labeled "pre-existing") and fixed.
None were regressions from §1 — two buckets predate it, one is a byproduct
of auth being added earlier and never revisited.

**Bucket A — 24 tests, stale auth setup.** `CashingReportControllerTest`,
`ExpenditureControllerTest`, `ReportControllerTest` (8 each) used a bare
`conn` from `ConnCase` with no `log_in_user`, so once these routes sat
behind the auth pipeline they hit a 302 redirect to `/login` instead of the
200 they expected. Fixed by adding a module-level `setup` that logs in a
platform-level user, matching the `log_in_user/2` pattern already
established in the sweep's own tests (e.g. `booking_controller_test.exs`).

**Bucket B — 8 tests, stale assumptions in `FinanceTest`.** Two distinct
causes:
- `assert record == Finance.get_x!(id)` compared an in-memory,
  freshly-inserted struct against a value read back from Postgres — decimal
  columns round-trip at the column's stored scale (`"120.5"` becomes
  `"120.50"`), so `Decimal.new("120.5") != Decimal.new("120.50")` under
  `==` even though they're the same value. Fixed by comparing the fields
  that matter with `Decimal.equal?/2` for money columns (two small local
  helpers, `assert_cashing_report_equal/2` and `assert_expenditure_equal/2`)
  instead of blanket struct equality — the same approach the file's own
  ledger tests already used (`Decimal.equal?` at lines 444/454).
- Two tests' `valid_attrs` never included `report_date`, which validation
  requires — masked until now because these tests never got far enough to
  hit it.

**Bucket C — 1 test, `PageControllerTest`, plus a real bug it uncovered.**
The test asserted `GET /` (logged out) showed default Phoenix-scaffold copy
("Peace of mind from prototype to production") that was never replaced.
Investigating what `/` actually renders surfaced a real, pre-existing bug:
`PageController` never got the `:public` layout that `PublicBookingController`
uses (`plug :put_layout, html: {FleetMintWeb.Layouts, :public}`) — every
`use FleetMintWeb, :controller` module defaults to the internal `:app`
sidebar layout, so the public landing page at `/` was rendering wrapped in
the admin nav sidebar for logged-out visitors. Fixed by scoping the same
`:public` layout plug to `PageController.home` only (`dashboard` keeps the
`:app` layout). The test now asserts the real landing copy.

## 3. Verification (reproducible)

```bash
mix format --check-formatted   # clean
mix compile                    # clean (pre-existing `prompt` attribute
                                # warnings noted in §5, not new, not gating)
MIX_ENV=test mix ecto.drop && MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate
mix test
```

Actual result: **242 tests, 0 failures** — up from 181 tests / 33 failures
at the Phase 4 checkpoint (37 new controller/context tests landed with §1's
commits; the pre-existing 33 are now fixed, not carried forward).

## 4. What is explicitly not built / not fixed here

- **No enumerated written list of the 13 org-scoping findings existed
  before this document.** The sweep commits (`c7ca4c5` onward) reference
  "findings #11-13" implying a working list from the session that produced
  them, but it was never committed. This checkpoint is the first written
  record; treat it as authoritative going forward.
- **Pre-existing compiler warnings** (`undefined attribute "prompt" for
  component FleetMintWeb.CoreComponents.input/1`, 7 occurrences across
  `cashing_report_html.ex`, `fuel_log_html.ex`, `minibus_trip_html.ex`,
  `vehicle_maintenance_html.ex`) were not touched — present before this
  phase, CI doesn't run `--warnings-as-errors`, and fixing them means
  touching the shared input/select component's attribute list, out of
  scope for a test-remediation pass.
- **`AuthController` (`/login`, `/register`) likely has the same missing
  `:public`-layout issue** `PageController` had (§2, Bucket C) — not
  verified or fixed here, since it wasn't one of the 33 failing tests. Worth
  a follow-up check.
- **Mobile app integration** (`mobile/` in this repo) — last known status is
  build-and-run with mock-data fallback; given how much backend surface has
  changed since, this needs a fresh check before trusting it.
- **Constitution Phases 6–7** (cargo lifecycle depth beyond what §1.2
  covers, payments/accounting/compliance, mobile auth) — not started.
- **Customer Portal, Driver Portal, dedicated Mobile API, Notifications
  surface** — the four platform-vision pieces still not built.

---

**Commit representing this checkpoint's test remediation: recorded in the
same commit as this document.**
