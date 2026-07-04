# FleetMint Ecosystem — Project Documentation

**Date:** 2026-06-11
**Last updated:** 2026-07-04 — platform reorganization (domain-driven module structure) and Guardian secret fix, see "Platform Reorganization" section below
**Framework:** Elixir / Phoenix 1.7.14
**Database:** PostgreSQL (port 5433)
**Running at:** `http://localhost:4004`

---

## Overview

FleetMint is a unified fleet management platform built for transport operators. It handles:

- Passenger transit — minibuses, schedules, bookings, QR tickets, live tracking
- Freight / haulage — truck trips, clients, orders, invoices
- Vehicle fleet — buses, trucks, maintenance, fuel logs
- Driver management — license tracking, pay rates, status
- Daily operations — trip logs, cashing reports, expenditures, PDF reports
- Operations diary — daily log of incidents, decisions, and events

Everything runs under one login with a dark sidebar interface.

---

## Technical Stack

| Item | Detail |
|---|---|
| Language | Elixir 1.16+ |
| Framework | Phoenix 1.7.14 |
| HTTP Server | Bandit |
| Database | PostgreSQL (port 5433, user: `think`, password: `password1`) |
| ORM | Ecto |
| Authentication | Guardian (JWT tokens) |
| Frontend | Tailwind CSS |
| Templates | HEEX (server-rendered HTML) |
| Dev Port | 4004 |

---

## Running the Server

```bash
cd /home/think/Fleet_Mint_Ecosystem

# Start the server
mix phx.server

# Access at:
http://localhost:4004

# Run migrations only
mix ecto.migrate

# Full reset (drop, create, migrate)
mix ecto.drop && mix ecto.create && mix ecto.migrate
```

---

## Project Structure

```
Fleet_Mint_Ecosystem/
├── config/
│   └── dev.exs                  # Port 4004, DB config
├── lib/
│   ├── fleet_mint/              # Business logic (contexts), organized by domain
│   │   ├── identity/             # User accounts + Guardian JWT auth
│   │   ├── transport/
│   │   │   ├── fleet/            # Vehicles, buses, routes, operators, maintenance, fuel
│   │   │   ├── trips/             # Schedules, minibus trips
│   │   │   ├── ticketing/         # Bookings, QR tickets
│   │   │   └── boarding.ex        # Ticket validation, GPS checkpoints, tracking
│   │   ├── cargo/                 # Freight clients, orders, trips, invoices
│   │   ├── finance/               # Cashing reports, expenditures, weekly reports
│   │   ├── hr/                    # Drivers
│   │   ├── administration/        # Operation logs, audit logs, complaints/feedback
│   │   ├── reporting/             # PDF generation
│   │   ├── notifications.ex
│   │   ├── pagination.ex
│   │   ├── payments.ex + payments/     # DEAD CODE — zero callers anywhere, kept in place
│   │   └── ticketing.ex + ticketing/   # DEAD CODE — zero callers anywhere, kept in place
│   └── fleet_mint_web/          # Web layer (controllers, templates) — unchanged file layout
│       ├── components/
│       │   └── layouts/
│       │       ├── app.html.heex      # Dark sidebar layout
│       │       └── root.html.heex
│       ├── controllers/         # One controller + html module per resource
│       └── router.ex            # All routes
└── priv/
    └── repo/
        └── migrations/          # 38 migration files
```

> The two "DEAD CODE" entries above are confirmed unused — zero callers anywhere in the app, and `Payments.Transaction` references a `ticket_id` column that was never migrated onto `transactions`. They're deliberately kept at their original top-level paths (not moved into a domain namespace) so the new module names don't inherit broken, unexercised code. Candidates for deletion in a future pass. See "Platform Reorganization" below.

---

## Database Tables (28 total)

| Table | Context | Purpose |
|---|---|---|
| `users` | Identity | Staff accounts with roles |
| `buses` | Transport.Fleet | Bus registry (separate from `vehicles`, bridged via `vehicle_id`) |
| `routes` | Transport.Fleet | Passenger routes with fares and stops |
| `vehicles` | Transport.Fleet | Unified fleet — buses + trucks |
| `bus_profiles` | Transport.Fleet | Extra detail for bus-type vehicles |
| `truck_profiles` | Transport.Fleet | Extra detail for truck-type vehicles |
| `operators` | Transport.Fleet | Bus companies / transport operator brands |
| `operator_routes` | Transport.Fleet | Join table linking operators to routes |
| `drivers` | HR | Driver profiles with license and pay info |
| `operation_logs` | Administration | Daily diary of fleet events |
| `audit_logs` | Administration | System audit trail (logins, 2FA, security events) |
| `complaints` | Administration | Passenger complaints and suggestions |
| `schedules` | Transport.Trips | Timetabled departures (route + vehicle + time) |
| `minibus_trips` | Transport.Trips | Daily trip log per bus run |
| `bookings` | Transport.Ticketing | Passenger bookings per schedule |
| `tickets` | Transport.Ticketing | QR-code tickets per booking |
| `bus_checkpoints` | Transport.Boarding | Live location updates from conductors |
| `cashing_reports` | Finance | End-of-shift cash summaries |
| `expenditures` | Finance | Operating expense records |
| `weekly_reports` | Finance | Weekly revenue summaries |
| `transactions` | *(dead code — Payments)* | Unused; `Payments` context has zero callers anywhere |
| `vehicle_maintenances` | Transport.Fleet | Service and repair records |
| `fuel_logs` | Transport.Fleet | Fuel fill records |
| `freight_clients` | Cargo | Haulage clients / companies |
| `freight_orders` | Cargo | Delivery orders |
| `freight_trips` | Cargo | Truck trip execution |
| `trip_milestones` | Cargo | Waypoints within a freight trip |
| `freight_invoices` | Cargo | Client invoices for freight work |

---

## Contexts (Business Logic)

Reorganized 2026-07-04 from a flat list of ~12 contexts into a domain-driven hierarchy — see "Platform Reorganization" below for why and how.

### `FleetMint.Identity`
Manages staff user accounts and authentication.
- Register, login, logout; account lockout after repeated failed attempts
- Password reset (hashed, expiring tokens) and TOTP two-factor auth
- Track who is on duty today (`list_on_duty_staff/0`)
- User roles: `admin`, `manager`, `cashier`, `operator`
- **`FleetMint.Identity.Guardian`** — JWT token generation/verification, used by `AuthPlug` to protect routes. Its signing secret is read from `GUARDIAN_SECRET_KEY` in production (fixed 2026-07-04 — previously hardcoded across all environments).

### `FleetMint.Transport.Fleet`
Everything related to the physical fleet.
- **Bus** — CRUD, count (separate table from `vehicles`, bridged via `vehicle_id`, not yet wired into any form)
- **Vehicle** — unified fleet (buses + trucks), active count
- **Route** — CRUD, count, stops
- **Operator** — bus company / route branding shown on the public booking portal
- **VehicleMaintenance** — service records, count pending
- **FuelLog** — fill records, total cost per vehicle, fuel cost today

### `FleetMint.Transport.Trips`
Schedules and minibus trip logs.
- **Schedule** — CRUD, seat inventory (`decrement_available_seat/1`, `increment_available_seat/1` — called by `Transport.Ticketing`)
- **MinibusTrip** — daily trip log, count today, revenue today

### `FleetMint.Transport.Ticketing`
Passenger bookings and QR ticket issuance.
- **Booking** — CRUD, count today, revenue today; creating a booking automatically issues a ticket and decrements the schedule's seat count via `Transport.Trips`
- **Ticket** — QR payload/SVG generation, HMAC validation token

### `FleetMint.Transport.Boarding`
Ticket validation and live location tracking.
- `validate_ticket/2` — boards a ticket (or rejects: already boarded / expired / cancelled)
- **BusCheckpoint** — GPS location updates posted by on-duty staff
- `track_by_booking_reference/1` — powers the public `/track` page

### `FleetMint.Cargo`
Haulage and logistics (renamed from `Freight`).
- **Client** — freight customers
- **Order** — delivery jobs
- **Trip** — execution of orders, milestone tracking, status updates
- **Invoice** — billing for completed work

### `FleetMint.Finance`
Financial records.
- **CashingReport** — shift-end cash summaries
- **Expenditure** — expense entries
- **Report** (weekly) — management summaries; also owns all Report CRUD directly now (a duplicate `FleetMint.Reports` wrapper context was deleted 2026-07-04)
- Stats: recent reports, recent transactions, expenditure count

### `FleetMint.HR`
Driver personnel records.
- **Driver** — CRUD, list active, count, list expiring licenses

### `FleetMint.Administration`
Staff-facing oversight and record-keeping (folds together three formerly separate contexts — `Operations.OperationLog`, `AuditLogs`, and `Feedback`).
- **OperationLog** — daily diary of fleet events, categorized (general/incident/maintenance/finance/staff/passenger)
- **AuditLog** — system audit trail (login attempts, 2FA events, lockouts); write with `log/2`, read with `list_recent_audit_logs/1` and `count_audit_logs_today/0`
- **Complaint** — passenger complaints and suggestions submitted via the public feedback form; `count_pending_complaints/0`

### `FleetMint.Reporting`
- **PdfGenerator** — renders daily summaries, weekly reports, booking receipts, and expenditure reports as PDFs via ChromicPDF

### `FleetMint.Payments` and `FleetMint.Ticketing` (top-level) — dead code, not part of the domain hierarchy
Both confirmed to have **zero callers anywhere in the app** as of 2026-07-04. `Payments.Transaction` declares a `belongs_to :ticket` needing a `ticket_id` column that no migration ever added to `transactions` — this code has never run end-to-end. `Ticketing.Ticket` (distinct from the real, active `Transport.Ticketing.Ticket`) declares columns that don't exist on the real `tickets` table. Left in place at their original paths rather than folded into `Finance`/`Transport.Ticketing`, so the new domain names don't inherit broken code. Candidates for deletion in a future pass.

---

## All Routes

### Public (no login required)

| Method | Path | Action |
|---|---|---|
| GET | `/` | Landing page (redirects to dashboard if logged in) |
| GET | `/login` | Login form |
| POST | `/login` | Authenticate |
| GET | `/register` | Register form |
| POST | `/register` | Create account |
| DELETE | `/logout` | Sign out |
| GET | `/book` | Public booking portal index |
| GET | `/book/:slug` | Select route to book |
| GET | `/book/:slug/:schedule_id` | Booking form |
| POST | `/book/:slug/:schedule_id` | Submit booking |
| GET | `/book/ticket/:reference` | View ticket by reference |
| GET | `/track` | Live bus tracking |

### Protected (login required)

| Method | Path | Controller |
|---|---|---|
| GET | `/dashboard` | PageController#dashboard |
| CRUD | `/buses` | BusController |
| CRUD | `/routes` | RouteController |
| CRUD | `/vehicles` | VehicleController |
| CRUD | `/operators` | OperatorController |
| CRUD | `/drivers` | DriverController |
| CRUD | `/maintenances` | VehicleMaintenanceController |
| CRUD | `/fuel_logs` | FuelLogController |
| CRUD | `/schedules` | ScheduleController |
| POST | `/schedules/:id/checkpoint` | ScheduleController#post_checkpoint |
| CRUD | `/bookings` | BookingController |
| GET | `/tickets` | TicketController#index |
| GET | `/tickets/:id` | TicketController#show |
| GET | `/tickets/:id/validate` | TicketController#validate |
| CRUD | `/minibus_trips` | MinibusTripController |
| CRUD | `/cashing_reports` | CashingReportController |
| CRUD | `/expenditures` | ExpenditureController |
| CRUD | `/reports` | ReportController |
| CRUD | `/operation_logs` | OperationLogController |
| CRUD | `/freight/clients` | FreightClientController |
| CRUD | `/freight/orders` | FreightOrderController |
| CRUD | `/freight/trips` | FreightTripController |
| POST | `/freight/trips/:id/milestones` | FreightTripController#add_milestone |
| PATCH | `/freight/trips/:id/status` | FreightTripController#update_status |
| CRUD | `/freight/invoices` | FreightInvoiceController |
| GET | `/admin/reports` | PdfReportController#index |
| GET | `/pdf/daily` | PdfReportController#daily |
| GET | `/pdf/weekly/:id` | PdfReportController#weekly |
| GET | `/pdf/receipt/:id` | PdfReportController#receipt |
| GET | `/pdf/expenditures` | PdfReportController#expenditures |

---

## Sidebar Navigation

```
FleetMint  (Miway Logistics)
────────────────────────────
  Dashboard

  FLEET
  ├── All Vehicles        /vehicles
  ├── Routes              /routes
  ├── Maintenance         /maintenances
  ├── Fuel Logs           /fuel_logs
  └── Drivers             /drivers

  TRANSIT
  ├── Schedules           /schedules
  ├── Bookings            /bookings
  ├── QR Tickets          /tickets
  ├── Bus Companies       /operators
  └── Daily Trips         /minibus_trips

  FREIGHT
  ├── Clients             /freight/clients
  ├── Orders              /freight/orders
  ├── Truck Trips         /freight/trips
  └── Invoices            /freight/invoices

  FINANCE
  ├── Cashing Reports     /cashing_reports
  └── Expenditures        /expenditures

  OPERATIONS
  └── Operations Log      /operation_logs

  REPORTS
  ├── Weekly Reports      /reports
  └── Print / PDF         /admin/reports

  ────────────────────────
  [Your Name]  [Role]
  Sign out
```

---

## Dashboard — Daily Login Screen

After signing in, the dashboard shows everything relevant for the day.

### Duty Profile Card
- Your avatar (initials), full name, role badge
- Staff ID (e.g. STAFF-0001), email, phone
- "On Duty Since" — your login time
- Today's date and ON DUTY indicator

### Today's Revenue (3 cards)
| Card | Source |
|---|---|
| Bookings Today | Count from `bookings` table |
| Ticket Revenue | Sum of fares from today's bookings |
| Trip Fare Today | Sum of `fare_collected` from today's minibus trips |

### Fleet Stats (6 cards)
| Card | Source | Notes |
|---|---|---|
| Buses | Count of `buses` table | Links to /buses |
| All Vehicles | Count of `vehicles` table | Links to /vehicles |
| Routes | Count of `routes` table | Links to /routes |
| Trips Today | Count of today's minibus_trips | Links to /minibus_trips/new |
| Pending Service | Count of scheduled/in_progress maintenances | Turns amber when > 0 |
| Fuel Cost Today | Sum of total_cost from today's fuel_logs | Links to /fuel_logs/new |

### Staff On Duty
All users who logged in today, shown as cards with avatar, role, staff ID, and phone number. You are highlighted in blue.

### Recent Reports
Last 5 weekly reports with ZMW amounts. Links to full reports list.

### Quick Actions
One-click buttons for the most common daily tasks:
- New Booking
- Cashing Report
- Expenditure
- Print PDF

### Client Mobile App Guide
Instructions for passengers to install the booking portal as a PWA on Android (Chrome) and iPhone (Safari), plus an explanation of how the QR ticket process works.

---

## Module Reference

### Drivers
**URL:** `/drivers`
**Fields:**

| Field | Type | Notes |
|---|---|---|
| name | string | Required |
| phone | string | Rendered as clickable tel: link |
| license_number | string | Must be unique |
| license_expiry | date | Shows ⚠ EXPIRED in red if past today |
| daily_rate | decimal | Pay per day in ZMW |
| date_hired | date | |
| status | string | active / inactive / suspended |
| notes | text | |

The index page shows a colored status badge and an expiry warning inline.

---

### Daily Trips (Minibus Trips)
**URL:** `/minibus_trips`
**Fields:**

| Field | Type | Notes |
|---|---|---|
| date | date | Required |
| bus_id | ref → buses | |
| route_id | ref → routes | |
| driver_id | ref → drivers | Repointed from `users` on 2026-07-04 |
| passengers_count | integer | |
| fare_collected | decimal | ZMW |
| fuel_cost | decimal | ZMW |
| status | string | scheduled / in_progress / completed / cancelled |
| notes | text | |

The show page displays **Net Profit = fare_collected − fuel_cost**.

---

### Vehicle Maintenance
**URL:** `/maintenances`
**Fields:**

| Field | Type | Notes |
|---|---|---|
| vehicle_id | ref → vehicles | |
| service_date | date | |
| service_type | string | oil_change, tyre_change, brake_service, engine_repair, body_work, electrical, inspection, other |
| status | string | scheduled / in_progress / completed |
| description | text | |
| cost | decimal | ZMW |
| mileage_at_service | integer | km |
| garage | string | Workshop name |
| next_service_date | date | Reminder |
| next_service_mileage | integer | km reminder |
| recorded_by_id | ref → users | Auto-set |

---

### Fuel Logs
**URL:** `/fuel_logs`
**Fields:**

| Field | Type | Notes |
|---|---|---|
| vehicle_id | ref → vehicles | |
| log_date | date | |
| fuel_type | string | petrol / diesel / cng |
| liters | decimal | |
| cost_per_liter | decimal | ZMW |
| total_cost | decimal | Auto-calculated: liters × cost_per_liter |
| mileage | integer | Odometer reading in km |
| fuel_station | string | |
| driver_id | ref → drivers | Optional; repointed from `users` on 2026-07-04 |
| notes | text | |

---

### Operations Log
**URL:** `/operation_logs`
**Fields:**

| Field | Type | Notes |
|---|---|---|
| date | date | Required |
| title | string | Short subject line, required |
| category | string | general / incident / maintenance / finance / staff / passenger |
| description | text | Full details |
| logged_by_id | ref → users | Auto-set to current user on create |

Category color coding on index: incident = red, maintenance = amber, finance = green, staff = blue, passenger = purple.

---

### Schedules
**URL:** `/schedules`

Links a bus, route, and departure time into a scheduled run. Conductors can post live checkpoint updates via `POST /schedules/:id/checkpoint` which feeds the public tracking page at `/track`.

---

### Bookings & QR Tickets
**URL:** `/bookings`, `/tickets`

Staff creates a booking for a passenger on a specific schedule. The system generates a QR code ticket. The conductor scans the QR at boarding. Clients can also self-book via the public portal at `/book`.

---

### Freight
**URL:** `/freight/clients`, `/freight/orders`, `/freight/trips`, `/freight/invoices`

Full haulage workflow:
1. Register a **client** (company or individual)
2. Create a **freight order** (cargo details, origin, destination)
3. Assign a truck, create a **freight trip**
4. Post **milestones** as the truck moves (departed, checkpoint, arrived)
5. Update **status** — `pending → in_transit → delivered`
6. Generate an **invoice** for the client

---

### Finance
**Cashing Reports** (`/cashing_reports`) — Cashiers submit an end-of-shift summary showing total cash received, expenses paid out, and net amount to hand over.

**Expenditures** (`/expenditures`) — Log any operating cost with date, description, and amount.

**Weekly Reports** (`/reports`) — Management-level weekly revenue summaries.

**PDF Reports** (`/admin/reports`) — Download any of the following as PDFs:
- Daily report
- Weekly report (by ID)
- Booking receipt (by ID)
- Full expenditure report

---

## Authentication Flow

1. User visits `/login`, enters credentials
2. `FleetMint.Identity.Guardian` generates a JWT token stored in the session
3. `AuthPlug` checks the token on every protected request
4. If valid — request proceeds, `current_user` is set in assigns
5. If invalid or missing — redirected to `/login`
6. `DELETE /logout` clears the session

User roles (`admin`, `manager`, `cashier`, `operator`) are stored on the user record. Route-level role restriction already exists via the `require_manager` and `require_admin` pipelines in `router.ex`.

---

## Public Booking Portal

Clients or passengers can book tickets without a staff account:

- **`/book`** — Lists available routes
- **`/book/:slug`** — Shows schedules for a chosen route
- **`/book/:slug/:schedule_id`** — Booking form (name, phone, seat)
- After booking: QR ticket displayed and can be saved/printed
- **`/book/ticket/:reference`** — Retrieve a ticket by reference number

---

## Other Projects on This Machine

| Project | Port | Description |
|---|---|---|
| `loan_system` | 4001 | Elixir/Phoenix loan management app |
| `miway_tech` | 4002 | Miway Tech company Phoenix app |
| `minibus_tracker` | 4003 | Original basic tracker (superseded by FleetMint) |
| `Fleet_Mint_Ecosystem` | **4004** | This system — main unified platform |

To start all servers, open a separate terminal for each:
```bash
cd /home/think/loan_system && mix phx.server
cd /home/think/miway_tech && mix phx.server
cd /home/think/Fleet_Mint_Ecosystem && mix phx.server
```

---

## Schema Hardening — 2026-07-04

A growth/scalability audit of the schema (29 tables at the time) found 7 issues, ranked by priority. Six are now fixed across 5 migrations; the 7th is deliberately deferred. No data migration was needed — every table was empty when these ran.

> Module names below (`FleetMint.Fleet`, `FleetMint.Operations`, `FleetMint.Accounts`) reflect what they were called at the time this work happened. A platform reorganization later the same day renamed them to `FleetMint.Transport.Fleet`, `FleetMint.HR`, and `FleetMint.Identity` respectively — see "Platform Reorganization" below.

**Migrations added:**

| File | What it does |
|---|---|
| `20260704155637_link_buses_to_vehicles_and_repoint_drivers.exs` | Bridges `buses` to `vehicles` and repoints driver FKs |
| `20260704162048_add_missing_foreign_key_indexes.exs` | Adds 18 indexes on previously unindexed FK columns |
| `20260704162049_standardize_monetary_column_precision.exs` | Scales legacy bare `numeric` money columns to `numeric(p,s)` |
| `20260704162050_add_status_check_constraints.exs` | Adds 28 `CHECK` constraints mirroring existing Ecto validations |
| `20260704162051_add_gin_indexes_for_array_columns.exs` | Adds GIN indexes to the 5 array columns |

**1. Bridged `buses` ↔ `vehicles`.** The legacy minibus-cashing tables (`buses`, `cashing_reports`, `minibus_trips`) and the newer fleet model (`vehicles` + `bus_profiles`) described the same physical bus with no link between them. Added `buses.vehicle_id → vehicles(id)` (`ON DELETE SET NULL`) and a matching `belongs_to :vehicle` on `FleetMint.Fleet.Bus`. This is a bridge, not a merge — the existing bus/minibus-trip controllers and templates are untouched. Fully retiring `buses` in favor of `vehicles`/`bus_profiles` remains a larger, separate decision (would mean rewriting the bus and minibus-trip UI).

**2. Repointed driver assignment at `drivers`, not `users`.** `drivers` holds license number, license expiry, and daily rate, but `schedules.driver_id`, `freight_trips.driver_id`/`co_driver_id`, `vehicles.current_driver_id`, `fuel_logs.driver_id`, and `minibus_trips.driver_id` all referenced `users.id` directly — so a trip could be assigned to a user with no driver profile, license, or status at all. All five now reference `drivers(id)`. `schedules.conductor_id` was left pointing at `users` — there's no `conductors` table. Updated in code:
- Ecto `belongs_to` targets on `Bus`, `Schedule`, `FuelLog`, `Freight.Trip`, `MinibusTrip`, `Vehicle`
- `MinibusTripController`, `FuelLogController`, `FreightTripController` now source driver dropdowns from `FleetMint.Operations.list_drivers()` instead of `Accounts.list_users_by_role("operator")`
- `minibus_trip_html.ex` and `fuel_log_html.ex` driver `<select>` options now read `driver.name` instead of `user.full_name`/`username`

**3. Added the 18 missing FK indexes** — columns like `bookings.booked_by_id`, `complaints.reviewed_by_id`, `schedules.driver_id`/`conductor_id`, and several `created_by_id`/`recorded_by_id` columns had no supporting index.

**4. Standardized monetary precision.** `cashing_reports` (4 columns), `expenditures.amount`, `transactions.amount`, and `vehicle_maintenances.cost` moved to `numeric(12,2)`; `fuel_logs.liters`/`cost_per_liter` and `minibus_trips.fare_collected`/`fuel_cost` moved to `numeric(10,2)` — matching the precision already used on the freight/booking tables.

**5. Added 28 `CHECK` constraints** so the database enforces the same status/category/type vocabularies as the Ecto changesets (`validate_inclusion`) across `buses`, `vehicles`, `bus_profiles`, `drivers`, `schedules`, `minibus_trips`, `bookings`, `tickets`, `complaints`, `freight_clients`, `freight_orders`, `freight_trips`, `freight_invoices`, `truck_profiles`, `vehicle_maintenances`, `operation_logs`, `fuel_logs`, `users`, and `transactions`. This closes the gap where a second write path (a script, another service, a bulk import) could previously insert any string.

  While tracing these, found that `tickets` has two disconnected schema modules: `FleetMint.Transit.Ticket` (the real one, matches the table) and an orphaned `FleetMint.Ticketing.Ticket` referencing columns (`passenger_name`, `route_id`, `bus_id`, `fare_amount`, etc.) that don't exist on the table at all. Left as-is — it's dead code, not one of the audit's original findings, and worth a separate cleanup pass.

**6. Added GIN indexes** on `routes.stops`, `schedules.days_of_week`, `bus_profiles.amenities`/`seat_labels`, and `truck_profiles.allowed_cargo_types` so array-containment queries can use an index once they're written.

**7. Partitioning — deferred on purpose.** `audit_logs`, `transactions`, `bookings`, `fuel_logs`, and `trip_milestones` are the append-heavy tables here, currently unpartitioned. Not fixed because, unlike the other six, it isn't additive: Postgres requires the partition key inside the primary key, which would force a composite key on `bookings`/`transactions` and cascade into every table referencing them (e.g. `tickets.booking_id`). Revisit once there's a real growth curve to pick the partitioning key against — almost certainly month, on `inserted_at`/`travel_date`.

---

## Platform Reorganization — 2026-07-04

The business-logic layer (`lib/fleet_mint/**`) was restructured from a flat list of ~12 top-level contexts into a domain-driven hierarchy, so module names speak the transport business's own vocabulary instead of generic CRUD naming, and so the app can keep adding features without every new concept landing in an already-crowded file:

```
FleetMint (Platform)
├── Identity
├── Transport
│     ├── Fleet
│     ├── Trips
│     ├── Ticketing
│     └── Boarding
├── Finance
├── HR
├── Cargo
├── Reporting
├── Notifications
└── Administration
```

This was a code-organization change only — **router paths, controller file names, and the database schema are all unchanged.** Only `alias` lines, cross-context schema associations, and Guardian's config keys moved. Done in 6 phased commits, each compiled clean and manually smoke-tested (route walk + direct context calls against the dev DB) before the next:

1. **`Accounts` → `Identity`** (+ `Auth.Guardian` → `Identity.Guardian`; all 4 config files' Guardian secret key updated in the same phase, so the fix below didn't silently stop applying)
2. **`Freight` → `Cargo`** — a clean, self-contained rename (4 controllers, 5 schemas)
3. **`Fleet` → `Transport.Fleet`** — `Operator` and `Route` stayed bundled in rather than split into their own contexts; neither has complexity driving a split yet
4. **`Transit` split into three** — the biggest phase. The old `Transit` context (310 lines) bundled schedules, minibus trips, bookings, tickets, and GPS checkpoints into one module. Split into:
   - **`Transport.Trips`** — Schedule + MinibusTrip CRUD, plus `decrement_available_seat/1`/`increment_available_seat/1` (promoted from private helpers so Ticketing can call them)
   - **`Transport.Ticketing`** — Booking + Ticket CRUD, QR/token generation; calls `Trips` for seat inventory on create/cancel
   - **`Transport.Boarding`** — ticket validation/boarding (moved out of a "Tickets" section it didn't really belong to), GPS checkpoints, reference tracking

   Dependency direction is Boarding → Ticketing → Trips, no cycles.
5. **`Operations` split into `HR` (Driver) and `Administration`** — `Administration` also absorbed `AuditLogs` (→ `Administration.AuditLog`) and `Feedback` (→ `Administration.Complaint`), since all three are staff-facing oversight/record-keeping concerns rather than distinct business domains. A few functions were renamed to avoid ambiguity now that they share a context: `AuditLogs.list_recent/1` → `list_recent_audit_logs/1`, `count_today/0` → `count_audit_logs_today/0`, `Feedback.count_pending/0` → `count_pending_complaints/0`.
6. **Deleted `FleetMint.Reports`**, a byte-for-byte duplicate of Report CRUD already living in `FleetMint.Finance` on the same `Finance.Report` schema (a pre-existing mismatch — a context named `Reports` operating on `Finance`'s schema). Repointed its one real caller (`report_controller.ex`) straight to `Finance`, and moved the one genuinely distinct piece, `PdfGenerator`, into `FleetMint.Reporting`.

**Two pre-existing bugs found and fixed while verifying the split (unrelated to the rename itself — same bugs existed in the original code, just newly exercised by smoke-testing):**
- `Ticket.board_changeset` stored an untruncated `NaiveDateTime` (`boarded_at`), which crashed on boarding with `Ecto.Type` microsecond errors.
- `complaint_html/new.html.heex` called `hd(@changeset.errors[:field])`, but `changeset.errors[:field]` already returns a single `{msg, opts}` tuple, not a list — `hd/1` crashed with `ArgumentError` on any blank feedback form, meaning the public `/feedback/new` page was broken before this fix.

**`FleetMint.Payments` and `FleetMint.Ticketing` (top-level) were deliberately left untouched** rather than folded into the new `Finance`/`Transport.Ticketing` namespaces. Both are confirmed dead code — see the Contexts section above — and moving broken, unexercised code under a legitimate-looking new name would be misleading. They're annotated with `DEAD CODE:` moduledocs and are candidates for deletion in a future pass.

**Verification:** `mix compile` clean at every phase; the full test suite's 39 pre-existing failures (traced to fixture data violating CHECK constraints from the Schema Hardening migrations above — unrelated to this reorg) are the exact same set before and after, by test name, regardless of run order; every route in `router.ex` returns the correct status code with zero server errors.

---

## Known Warnings (non-breaking)

The following compile warnings exist but do not affect functionality:

- `undefined attribute "prompt"` on select inputs in maintenance, fuel log, and trip HTML modules — the `prompt` attribute works at runtime via Phoenix form helpers even though the compile-time checker does not recognise it on the custom `input` component.

---

## Planned / Possible Next Features

- Monthly salary / payroll calculation based on driver daily rate × trips worked
- Income vs Expenditure summary page (profit/loss view)
- Role-based access control (e.g. cashiers cannot delete drivers)
- SMS or email notification on new booking
- Mobile-responsive improvements for field staff
- Export data to CSV / Excel

---

*Documentation generated 2026-06-11. Maintained alongside the codebase at `/home/think/Fleet_Mint_Ecosystem`.*
