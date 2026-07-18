# Phase 2 Checkpoint: the canonical Trip model (2a + 2b)

Same evidence standard as [`phase1_tenancy_checkpoint.md`](./phase1_tenancy_checkpoint.md): a written record with reproducible verification commands, not a prose "it's done" claim.

## 1. What Phase 2 was

The Constitution requires a canonical Route → Schedule → Trip chain: a Trip is one dated instance of a Schedule. Before this phase, two tables used their own incompatible pseudo-Trip keys instead of a real Trip: `bus_checkpoints` (keyed on `(schedule_id, travel_date)`) and `cashing_reports` (keyed on `bus_id` + `report_date`, with no relation to Schedule at all).

Split into two parts because they turned out to be different-sized problems:

- **2a** — introduce `trips`, migrate `bus_checkpoints` onto it. Unambiguous by construction: a checkpoint's existing `(schedule_id, travel_date)` *is* a Trip's natural key.
- **2b** — connect `cashing_reports` to Trip. Not unambiguous: a cashing_report only has `bus_id`, and the bridge from bus to schedule (`bus → vehicle_id → schedule.vehicle_id`) is unpopulated in production (`buses.vehicle_id` is `NULL` on every row today). Guessing was explicitly ruled out; this required a real reconciliation model instead of a rename.

## 2. Phase 2a — `trips` + `bus_checkpoints` (commit `ea1df9e`, already shipped)

- `trips` table: `schedule_id`, `organisation_id` (denormalized from `schedule.operator.organisation_id`, the target of every composite FK below), `travel_date`, `status` (`planned`/`dispatched`/`active`/`completed`/`cancelled`), nullable `vehicle_id`/`driver_id`/`conductor_id` overrides of the Schedule's usual assignment, `unique_index([:schedule_id, :travel_date])`, `unique_index([:id, :organisation_id])` (composite FK target).
- `bus_checkpoints` migrated onto `trip_id`/`organisation_id` with a hard-stop backfill (`RAISE EXCEPTION` if any row can't be mapped — none could, dev had 0 checkpoints) and a composite `(trip_id, organisation_id) → trips(id, organisation_id)` foreign key.
- `Boarding.post_checkpoint/1` resolves-or-creates the Trip and stamps both fields from it — never from caller input.
- `schedule_id`/`travel_date` deliberately left on `bus_checkpoints` (not dropped) per "remove obsolete columns only after verification."

## 3. Phase 2b — `cashing_report_trips` reconciliation model (this work)

### 3.1 Schema

- **`cashing_report_trips`** (migration `20260718090001`): the allocation table. `cashing_report_id` (FK, `on_delete: :delete_all`), `trip_id` + `organisation_id` (composite FK to `trips(id, organisation_id)`, same tenant-isolation pattern as `bus_checkpoints`), `allocated_amount` (a report's cash can be split across more than one Trip), `match_method` (`automatic`/`manual`, DB check constraint), `matched_at`, `matched_by_id` (null for automatic matches). `unique_index([:cashing_report_id, :trip_id])` — a report can't be allocated to the same Trip twice.
- **`cashing_reports.trip_mapping_status`** (migration `20260718090007`): `pending` / `automatically_matched` / `manually_matched` / `ambiguous` / `unmappable`, DB check constraint, default `pending`. Plus `trip_mapping_notes` (text) — the *reason*, always populated, never a silent blank.
- A row in `cashing_report_trips` only exists once a match is established. An unmatched report carries its status/notes and no row — nothing is ever fabricated to satisfy a non-null foreign key.

### 3.2 The matching algorithm (`Finance.attempt_trip_match/1`)

For a report with `bus_id` set: find the bus's `vehicle_id`, then every schedule that vehicle has ever been assigned to, restricted to schedules whose operator's `organisation_id` matches the bus's own (cross-tenant vehicle sharing is a data-integrity anomaly, not a valid candidate).

| Candidates found | Existing Trip on that date? | Result |
|---|---|---|
| 0 (no bus / no vehicle / no schedule / only cross-org schedules) | — | `unmappable`, with a specific reason |
| 1 | yes | `automatically_matched` — allocation row created, full `received_cashing` amount |
| 1 | no | `unmappable` — "a schedule was found, but no Trip is recorded for that date" (does **not** create one) |
| 2+ | — | `ambiguous` — needs a human to pick |

Run automatically inside `Finance.create_cashing_report/1`'s transaction (`Ecto.Multi.merge`), so every new report is classified at creation time — this is not a one-off migration-only pass. Manual reconciliation for `ambiguous`/`unmappable` reports is `Finance.match_cashing_report_to_trip/4`, which rejects (without writing anything) if the report's bus and the chosen Trip belong to different organisations — enforced in application code because `cashing_reports` has no `organisation_id` column of its own to hang a composite FK off of.

### 3.3 Migration backfill result on the real dev database

```
select trip_mapping_status, trip_mapping_notes, count(*) from cashing_reports group by 1,2;

 trip_mapping_status |       trip_mapping_notes        | count
----------------------+---------------------------------+-------
 unmappable          | No bus recorded on this report. |    10

select count(*) from cashing_report_trips;
 count
-------
     0
```

All 10 existing reports have no `bus_id` at all, so all 10 are honestly `unmappable` — zero automatic matches, zero fabricated Trip links. This is the correct outcome given the data, not a bug: there was nothing to match against.

### 3.4 The trip-matching UI (commit `353f437`, follow-on to this checkpoint)

`GET /cashing_reports/unmatched` (the work queue, organisation-scoped), `GET`/`POST /cashing_reports/:id/trip_match` (candidate trips within 3 days of the report's date, drawn from the whole organisation rather than just the report's own bus/vehicle chain — manual reconciliation is exactly the case where that chain already failed to produce a candidate). Both write actions gated to admin/manager, matching this controller's existing `edit`/`update`/`delete` gating. Named "trip matching" rather than "reconciliation" — `ReconciliationController` already exists in the app for something unrelated (cash-vs-trip-log variance checking) and reusing the name would collide. Manually exercised against a running dev server (automatic match, manual match, cross-organisation rejection via both the UI's own candidate list and a hand-crafted bypass request, cashier role blocked) before being written up as 6 automated controller tests.

### 3.5 What is still not built

- No "suspense account" GL construct. `Accounting.record_entry/1` already records every cashing_report's cash in the ledger regardless of reconciliation state (unchanged by this phase), so cash is never lost or hidden — `trip_mapping_status` is purely the flag that lets Finance reporting distinguish trip-attributed cash from not-yet-attributed cash without touching the ledger.
- `update_cashing_report/2` does not re-attempt matching if a report's `bus_id` is corrected after creation (e.g. someone fills in a blank bus later). Named here as a known gap, not silently skipped.

## 4. Tests added this phase (13 new, all passing)

| File | Tests | What it proves |
|---|---|---|
| `test/fleet_mint/finance_test.exs` — `attempt_trip_match/1` | 7 | All five classification outcomes: no bus, bus without vehicle, vehicle never scheduled, matching schedule but no Trip that date, cross-organisation vehicle sharing, ambiguous (2 schedules), and the single-candidate-with-an-existing-Trip automatic match |
| `test/fleet_mint/finance_test.exs` — `create_cashing_report/1` integration | 2 | Automatic allocation + status update happen atomically on creation; an unmatchable report is left `unmappable` with zero rows in `cashing_report_trips` (nothing fabricated) |
| `test/fleet_mint/finance_test.exs` — `match_cashing_report_to_trip/4` | 3 | Manual match of an `unmappable`/`ambiguous` report; rejection across organisations (no write happens on either record); rejection when the report has no bus at all |
| `test/fleet_mint/finance_test.exs` — DB-level isolation | 1 | A deliberately mismatched `(trip_id, organisation_id)` pair is rejected by Postgres itself via the composite FK — `assert_raise Ecto.ConstraintError`, same proof pattern as `bus_checkpoints` in Phase 2a |

## 5. Verification (reproducible)

```bash
# Full current suite
mix test

# Exact current failure names
mix test 2>&1 | grep -E "^\s*[0-9]+\) test" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]*//' | sort > current_failures.txt

# Compare against the Phase 1 checkpoint's verbatim 33-name list
# (docs/phase1_tenancy_checkpoint.md, section 7)
diff current_failures.txt phase1_baseline.txt   # empty output = proof
```

Actual result at the commit representing this phase: **146 tests, 113 passing, 33 known pre-existing failures — byte-for-byte identical to the Phase 1 baseline list (`diff` exit 0), 0 new failures.** 13 new tests, all passing, none among the 33.

## 6. Result, stated precisely

Phase 2a: functionally complete, shipped in `ea1df9e`.

Phase 2b: functionally complete for the reconciliation *model and matching logic*; the reconciliation *UI* for ops/finance staff is a named, separate, not-yet-started follow-on (§3.4). This must not be read as "cashing_reports are now linked to trips" in production — with `buses.vehicle_id` unpopulated everywhere, the honest current state is that all 10 real reports are `unmappable`, correctly, until vehicle assignment data exists to match against.

---

**Commits representing Phase 2 completion: `ea1df9e` (2a), `aa5d035` (2b, this checkpoint's own commit).**
