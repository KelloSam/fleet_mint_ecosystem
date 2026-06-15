# FleetMint Ecosystem — Project Documentation

**Date:** 2026-06-11
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
│   ├── fleet_mint/              # Business logic (contexts)
│   │   ├── accounts/            # User accounts, auth
│   │   ├── auth/                # Guardian JWT
│   │   ├── fleet/               # Vehicles, buses, routes, maintenance, fuel
│   │   ├── operations/          # Drivers, operation logs
│   │   ├── transit/             # Schedules, bookings, tickets, trips
│   │   ├── finance/             # Cashing reports, expenditures, reports
│   │   ├── freight/             # Freight clients, orders, trips, invoices
│   │   ├── payments/            # Transaction ledger
│   │   ├── ticketing/           # QR ticket validation
│   │   └── reports/             # PDF generation
│   └── fleet_mint_web/          # Web layer (controllers, templates)
│       ├── components/
│       │   └── layouts/
│       │       ├── app.html.heex      # Dark sidebar layout
│       │       └── root.html.heex
│       ├── controllers/         # One controller + html module per resource
│       └── router.ex            # All routes
└── priv/
    └── repo/
        └── migrations/          # 24 migration files
```

---

## Database Tables (25 total)

| Table | Context | Purpose |
|---|---|---|
| `users` | Accounts | Staff accounts with roles |
| `buses` | Fleet | Bus registry |
| `routes` | Fleet | Passenger routes with fares and stops |
| `vehicles` | Fleet | Unified fleet — buses + trucks |
| `bus_profiles` | Fleet | Extra detail for bus-type vehicles |
| `truck_profiles` | Fleet | Extra detail for truck-type vehicles |
| `operators` | Fleet | Bus companies / transport operators |
| `drivers` | Operations | Driver profiles with license and pay info |
| `operation_logs` | Operations | Daily diary of fleet events |
| `schedules` | Transit | Timetabled departures (route + bus + time) |
| `bookings` | Transit | Passenger bookings per schedule |
| `tickets` | Transit / Ticketing | QR-code tickets per booking |
| `bus_checkpoints` | Transit | Live location updates from conductors |
| `minibus_trips` | Transit | Daily trip log per bus run |
| `cashing_reports` | Finance | End-of-shift cash summaries |
| `expenditures` | Finance | Operating expense records |
| `transactions` | Payments | Financial transaction ledger |
| `weekly_reports` | Finance | Weekly revenue summaries |
| `vehicle_maintenances` | Fleet | Service and repair records |
| `fuel_logs` | Fleet | Fuel fill records |
| `freight_clients` | Freight | Haulage clients / companies |
| `freight_orders` | Freight | Delivery orders |
| `freight_trips` | Freight | Truck trip execution |
| `trip_milestones` | Freight | Waypoints within a freight trip |
| `freight_invoices` | Freight | Client invoices for freight work |

---

## Contexts (Business Logic)

### `FleetMint.Accounts`
Manages staff user accounts.
- Register, login, logout
- Track who is on duty today (`list_on_duty_staff/0`)
- User roles: `admin`, `cashier`, `driver`, `manager`

### `FleetMint.Auth`
Guardian JWT authentication.
- Generates and verifies tokens
- Used by `AuthPlug` to protect routes

### `FleetMint.Fleet`
Everything related to the physical fleet.
- **Buses** — CRUD, count
- **Routes** — CRUD, count, stops
- **Vehicles** — unified fleet (buses + trucks), active count
- **Operators** — bus companies
- **VehicleMaintenance** — service records, count pending
- **FuelLog** — fill records, total cost per vehicle, fuel cost today

### `FleetMint.Operations`
Driver and operational management.
- **Driver** — CRUD, list active, count, list expiring licenses
- **OperationLog** — CRUD, list by date, list recent

### `FleetMint.Transit`
Passenger transport operations.
- **Schedule** — CRUD, checkpoints
- **Booking** — CRUD, count today, revenue today
- **Ticket** — QR code generation and validation
- **BusCheckpoint** — live tracking updates
- **MinibusTrip** — daily trip log, count today, revenue today

### `FleetMint.Finance`
Financial records.
- **CashingReport** — shift-end cash summaries
- **Expenditure** — expense entries
- **Report** (weekly) — management summaries
- Stats: recent reports, recent transactions, expenditure count

### `FleetMint.Freight`
Haulage and logistics.
- **Client** — freight customers
- **Order** — delivery jobs
- **Trip** — execution of orders, milestone tracking, status updates
- **Invoice** — billing for completed work

### `FleetMint.Payments`
Transaction ledger for financial records.

### `FleetMint.Ticketing`
QR ticket management and validation.

### `FleetMint.Reports`
PDF generation for:
- Daily summary reports
- Weekly reports
- Booking receipts
- Expenditure reports

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
| driver_id | ref → users | Staff member who drove |
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
| driver_id | ref → users | Optional |
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
2. Guardian generates a JWT token stored in the session
3. `AuthPlug` checks the token on every protected request
4. If valid — request proceeds, `current_user` is set in assigns
5. If invalid or missing — redirected to `/login`
6. `DELETE /logout` clears the session

User roles (`admin`, `cashier`, `driver`, `manager`) are stored on the user record. Role-based access control can be added per route or controller action using `current_user.role`.

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

## Known Warnings (non-breaking)

The following compile warnings exist but do not affect functionality:

- `undefined attribute "prompt"` on select inputs in maintenance, fuel log, and trip HTML modules — the `prompt` attribute works at runtime via Phoenix form helpers even though the compile-time checker does not recognise it on the custom `input` component.

---

## Planned / Possible Next Features

- Driver assignment directly on trip records (link drivers table to minibus_trips)
- Monthly salary / payroll calculation based on driver daily rate × trips worked
- Income vs Expenditure summary page (profit/loss view)
- Role-based access control (e.g. cashiers cannot delete drivers)
- SMS or email notification on new booking
- Mobile-responsive improvements for field staff
- Export data to CSV / Excel

---

*Documentation generated 2026-06-11. Maintained alongside the codebase at `/home/think/Fleet_Mint_Ecosystem`.*
