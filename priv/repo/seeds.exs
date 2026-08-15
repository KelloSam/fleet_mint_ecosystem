# ============================================================
# FleetMint development seed data
#
# Run with:  mix run priv/repo/seeds.exs
# (also runs automatically as part of `mix setup` / `mix ecto.setup`)
#
# WHAT THIS IS
# Entirely fictional, deterministic development/demo data. It exercises
# the tenant/role/operational boundaries FleetMint actually has
# implemented as of Stage B (see docs/PLATFORM_ARCHITECTURE_ROADMAP.md),
# nothing further ahead.
#
# WHAT THIS IS NOT
# This is NOT pilot data. The real FleetMint pilot organisation
# (Mazhandu Family Bus Services — Architecture Decision Queue item 9,
# Stage A) is a separate business decision with its own onboarding
# process (see docs/pilot/PILOT_DEFINITION.md) and must never be seeded
# here. Committing a real organisation's operational, staff, or
# financial data to this file would defeat the point of a public/shared
# dev seed — don't do it, no matter how convenient it seems at the time.
#
# TWO TENANTS ON PURPOSE
# Tenant isolation is a core architectural guarantee (Phase 1 onward) —
# one tenant alone can't demonstrate it. "Kalemba Coachlines" is a
# complete reference tenant (passenger transport + a freight side
# operation) touching every implemented domain. "Chibolya Logistics" is
# deliberately a *freight-only* organisation with no Operator profile at
# all — the exact case that motivated Stage B's Branch/Terminal
# re-parenting to Organisation rather than Operator (a logistics hub has
# no bus operations to hang a Branch off of).
#
# Safe to re-run against a fresh database. Not idempotent against a
# database that already has this data — re-running twice against the
# same DB will hit unique-constraint errors (slugs, registration
# numbers), which is the correct/expected signal to drop and recreate
# instead of silently duplicating.

alias FleetMint.Repo
alias FleetMint.Identity.{Organisation, Users}
alias FleetMint.Transport.{Fleet, Routes, Trips, Ticketing}
alias FleetMint.HR
alias FleetMint.Finance
alias FleetMint.Cargo
alias FleetMint.Administration

dev_password = "DevPassword123!"

IO.puts("\n== FleetMint dev seed: Tenant 1 — Kalemba Coachlines (complete reference tenant) ==")

{:ok, kalemba_operator} =
  Fleet.create_operator(%{
    name: "Kalemba Coachlines",
    slug: "kalemba-coachlines",
    tagline: "Zambia's Reliable Road Companion",
    contact_phone: "+260 97 111 2222",
    contact_email: "info@kalemba.example",
    color: "#0f766e"
  })

kalemba_org_id = kalemba_operator.organisation_id

{:ok, kalemba_admin} =
  Users.create_user(%{
    username: "kalemba_admin",
    email: "admin@kalemba.example",
    password: dev_password,
    role: "tenant_admin",
    full_name: "Grace Mulenga",
    title: "Director",
    phone: "+260 97 100 0001",
    active: true,
    organisation_id: kalemba_org_id
  })

{:ok, kalemba_manager} =
  Users.create_user(%{
    username: "kalemba_manager",
    email: "manager@kalemba.example",
    password: dev_password,
    role: "manager",
    full_name: "Brian Phiri",
    title: "Operations Manager",
    phone: "+260 97 100 0002",
    active: true,
    organisation_id: kalemba_org_id
  })

{:ok, kalemba_cashier} =
  Users.create_user(%{
    username: "kalemba_cashier",
    email: "cashier@kalemba.example",
    password: dev_password,
    role: "cashier",
    full_name: "Chanda Banda",
    title: "Cashier",
    phone: "+260 97 100 0003",
    active: true,
    organisation_id: kalemba_org_id
  })

{:ok, kalemba_branch} =
  Fleet.create_branch(%{
    name: "Lusaka Head Office",
    city: "Lusaka",
    organisation_id: kalemba_org_id
  })

{:ok, kalemba_terminal} =
  Fleet.create_terminal(%{
    name: "Lusaka Main Boarding Point",
    address: "Intercity Bus Terminus, Dedan Kimathi Road",
    branch_id: kalemba_branch.id
  })

{:ok, lsk_liv_route} =
  Routes.create_route(%{
    name: "Lusaka - Livingstone",
    status: "active",
    start_location: "Lusaka",
    end_location: "Livingstone",
    distance: "470.0",
    duration: 330,
    fare: "270.00"
  })

{:ok, lsk_ndola_route} =
  Routes.create_route(%{
    name: "Lusaka - Ndola",
    status: "active",
    start_location: "Lusaka",
    end_location: "Ndola",
    distance: "320.0",
    duration: 240,
    fare: "150.00"
  })

{:ok, kalemba_driver} =
  HR.create_driver(%{
    name: "Emmanuel Zulu",
    phone: "+260 96 200 0001",
    license_number: "DL-KAL-001",
    license_expiry: Date.add(Date.utc_today(), 365),
    daily_rate: "350.00",
    date_hired: ~D[2024-02-01],
    status: "active",
    organisation_id: kalemba_org_id
  })

{:ok, kalemba_vehicle} =
  Fleet.create_vehicle(%{
    "registration_number" => "BAK 1234",
    "make" => "Scania",
    "model" => "K410",
    "year" => "2021",
    "vehicle_type" => "bus",
    "status" => "active",
    "organisation_id" => kalemba_org_id,
    "current_driver_id" => kalemba_driver.id,
    "bus_profile" => %{
      "seating_capacity" => 65,
      "route_type" => "intercity",
      "amenities" => ["ac", "usb_charging", "reclining_seats"]
    }
  })

{:ok, kalemba_bus} =
  Fleet.create_bus(%{
    registration_number: "BAK1234",
    capacity: 65,
    model: "Scania K410",
    year: 2021,
    status: "active",
    description:
      "Same physical bus as vehicle BAK 1234 — Bus and Vehicle remain separate, unbridged records in this codebase (documented gap, see 2026-07-04 schema audit).",
    organisation_id: kalemba_org_id
  })

{:ok, kalemba_truck} =
  Fleet.create_vehicle(%{
    "registration_number" => "BAK 5678",
    "make" => "Isuzu",
    "model" => "FVR",
    "year" => "2020",
    "vehicle_type" => "truck",
    "status" => "active",
    "organisation_id" => kalemba_org_id,
    "truck_profile" => %{
      "payload_capacity_tons" => "8.0",
      "truck_category" => "rigid",
      "allowed_cargo_types" => ["general_cargo", "agricultural_produce"]
    }
  })

{:ok, kalemba_schedule} =
  Trips.create_schedule(%{
    departure_time: ~T[07:00:00],
    estimated_arrival_time: ~T[12:30:00],
    days_of_week: ~w(mon tue wed thu fri sat sun),
    fare: "270.00",
    available_seats: 65,
    status: "active",
    route_id: lsk_liv_route.id,
    operator_id: kalemba_operator.id,
    vehicle_id: kalemba_vehicle.id,
    driver_id: kalemba_driver.id
  })

{:ok, _kalemba_trip} = Trips.get_or_create_trip(kalemba_schedule.id, Date.utc_today())

{:ok, kalemba_booking} =
  Ticketing.create_booking(
    %{
      "schedule_id" => kalemba_schedule.id,
      "travel_date" => Date.to_iso8601(Date.utc_today()),
      "passenger_name" => "Mutinta Sinyangwe",
      "passenger_phone" => "+260 96 555 0101",
      "seat_number" => "12A",
      "fare_paid" => "270.00",
      "payment_method" => "airtel_money",
      "payment_reference" => "CI250815.0930.A11223",
      "terminal_id" => kalemba_terminal.id
    },
    kalemba_cashier.id
  )

{:ok, _kalemba_minibus_trip} =
  Trips.create_minibus_trip(%{
    date: Date.utc_today(),
    bus_id: kalemba_bus.id,
    route_id: lsk_ndola_route.id
  })

{:ok, kalemba_report} =
  Finance.create_report(%{start_date: Date.add(Date.utc_today(), -7), end_date: Date.utc_today()})

{:ok, kalemba_cashing_report} =
  Finance.create_cashing_report(
    %{
      days_worked: 6,
      expected_cashing: "9000.00",
      received_cashing: "8200.00",
      airtel_id: "CI250815.0930.A11223",
      debt_balance: "800.00",
      expenditure: "600.00",
      description: "Week of #{Date.add(Date.utc_today(), -7)} — Lusaka-Ndola route",
      report_id: kalemba_report.id,
      report_date: Date.utc_today(),
      bus_id: kalemba_bus.id
    },
    kalemba_cashier.id
  )

{:ok, _kalemba_expenditure} =
  Finance.create_expenditure(
    %{
      amount: "600.00",
      description: "Fuel top-up, Lusaka-Ndola route",
      cashing_report_id: kalemba_cashing_report.id,
      date: DateTime.utc_now()
    },
    kalemba_cashier.id
  )

{:ok, _kalemba_fuel_log} =
  Fleet.create_fuel_log(%{
    log_date: Date.utc_today(),
    liters: "180.0",
    vehicle_id: kalemba_vehicle.id
  })

{:ok, _kalemba_maintenance} =
  Fleet.create_maintenance(%{
    service_date: Date.add(Date.utc_today(), -30),
    service_type: "oil_change",
    vehicle_id: kalemba_vehicle.id
  })

{:ok, kalemba_freight_client} =
  Cargo.create_client(%{
    company_name: "Copperbelt Agro Supplies",
    client_type: "farm",
    contact_person: "Peter Mwansa",
    phone: "+260 95 300 0001",
    email: "peter@copperbeltagro.example",
    city: "Ndola",
    organisation_id: kalemba_org_id
  })

{:ok, kalemba_freight_order} =
  Cargo.create_order(
    %{
      "cargo_type" => "agricultural_produce",
      "origin" => "Lusaka",
      "destination" => "Ndola",
      "client_id" => kalemba_freight_client.id
    },
    kalemba_manager.id
  )

{:ok, kalemba_freight_trip} =
  Cargo.create_trip(
    %{
      "origin" => "Lusaka",
      "destination" => "Ndola",
      "vehicle_id" => kalemba_truck.id
    },
    kalemba_manager.id
  )

{:ok, _kalemba_freight_invoice} =
  Cargo.create_invoice(
    %{
      "invoice_date" => Date.utc_today(),
      "base_amount" => "3500.00",
      "client_id" => kalemba_freight_client.id,
      "trip_id" => kalemba_freight_trip.id
    },
    kalemba_manager.id
  )

{:ok, _kalemba_operation_log} =
  Administration.create_operation_log(%{
    date: Date.utc_today(),
    title: "New terminal opened",
    description: "Lusaka Main Boarding Point brought online under the new Branch/Terminal model.",
    category: "general",
    logged_by_id: kalemba_admin.id,
    organisation_id: kalemba_org_id
  })

{:ok, _kalemba_complaint} =
  Administration.create_complaint(%{
    type: "complaint",
    category: "punctuality",
    passenger_name: "Mutinta Sinyangwe",
    passenger_phone: "+260 96 555 0101",
    booking_reference: kalemba_booking.booking_reference,
    subject: "Departure delayed by 40 minutes",
    description: "Bus left Lusaka terminal well after the scheduled 07:00 departure."
  })

IO.puts(
  "Kalemba Coachlines: organisation ##{kalemba_org_id}, operator ##{kalemba_operator.id}, " <>
    "1 branch, 1 terminal, 3 staff users, 1 driver, 1 bus vehicle + 1 bus record, 1 truck, " <>
    "2 routes, 1 schedule, 1 trip, 1 booking, 1 minibus trip, 1 cashing report + expenditure, " <>
    "1 fuel log, 1 maintenance record, 1 freight client/order/trip/invoice, 1 operation log, 1 complaint."
)

IO.puts("\n== FleetMint dev seed: Tenant 2 — Chibolya Logistics (freight-only, no Operator) ==")

# No FleetMint.Transport.Fleet.create_operator/1 call here on purpose —
# Chibolya has no passenger-transport brand at all, so there is nothing
# to bundle an Operator profile with. This is a real, currently-open gap
# worth naming plainly: no context function in this codebase can create
# an Organisation on its own (Fleet.create_operator/1 is the only public
# "onboard a tenant" entrypoint, and it always creates an Operator
# alongside it). A logistics-only or government-department tenant —
# exactly the case Stage B's Branch/Terminal design was built for —
# currently has no admin-UI onboarding path. Inserting the Organisation
# directly here is correct for a seed script; it should not be read as
# proof this is fine for production onboarding too.
{:ok, chibolya_org} =
  %Organisation{}
  |> Organisation.changeset(%{name: "Chibolya Logistics", slug: "chibolya-logistics"})
  |> Repo.insert()

{:ok, chibolya_admin} =
  Users.create_user(%{
    username: "chibolya_admin",
    email: "admin@chibolya.example",
    password: dev_password,
    role: "tenant_admin",
    full_name: "Joseph Tembo",
    title: "General Manager",
    phone: "+260 97 400 0001",
    active: true,
    organisation_id: chibolya_org.id
  })

{:ok, _chibolya_branch} =
  Fleet.create_branch(%{name: "Chibolya Depot", city: "Lusaka", organisation_id: chibolya_org.id})

{:ok, chibolya_truck} =
  Fleet.create_vehicle(%{
    "registration_number" => "BAL 9012",
    "make" => "Fuso",
    "model" => "Fighter",
    "year" => "2019",
    "vehicle_type" => "truck",
    "status" => "active",
    "organisation_id" => chibolya_org.id,
    "truck_profile" => %{
      "payload_capacity_tons" => "12.0",
      "truck_category" => "flatbed",
      "allowed_cargo_types" => ["cement", "steel"]
    }
  })

{:ok, chibolya_client} =
  Cargo.create_client(%{
    company_name: "Kabwe Cement Distributors",
    client_type: "general_business",
    contact_person: "Ruth Chishimba",
    phone: "+260 95 600 0001",
    email: "ruth@kabwecement.example",
    city: "Kabwe",
    organisation_id: chibolya_org.id
  })

{:ok, chibolya_order} =
  Cargo.create_order(
    %{
      "cargo_type" => "cement",
      "origin" => "Kabwe",
      "destination" => "Lusaka",
      "client_id" => chibolya_client.id
    },
    chibolya_admin.id
  )

{:ok, chibolya_trip} =
  Cargo.create_trip(
    %{"origin" => "Kabwe", "destination" => "Lusaka", "vehicle_id" => chibolya_truck.id},
    chibolya_admin.id
  )

{:ok, _chibolya_invoice} =
  Cargo.create_invoice(
    %{
      "invoice_date" => Date.utc_today(),
      "base_amount" => "5200.00",
      "client_id" => chibolya_client.id,
      "trip_id" => chibolya_trip.id
    },
    chibolya_admin.id
  )

IO.puts(
  "Chibolya Logistics: organisation ##{chibolya_org.id} (no Operator profile — freight-only), " <>
    "1 branch, 1 tenant_admin user, 1 truck, 1 freight client/order/trip/invoice."
)

IO.puts("\n== FleetMint dev seed: platform-level staff ==")

{:ok, _platform_admin} =
  Users.create_user(%{
    username: "platform_admin",
    email: "platform@miway.example",
    password: dev_password,
    role: "platform_admin",
    full_name: "Miway Platform Staff",
    active: true,
    organisation_id: nil
  })

IO.puts("Platform admin: platform@miway.example — sees every organisation, tied to none.")

IO.puts("""

== Dev seed complete ==
All seed users share the password: #{dev_password}
  admin@kalemba.example      (tenant_admin, Kalemba Coachlines)
  manager@kalemba.example    (manager, Kalemba Coachlines)
  cashier@kalemba.example    (cashier, Kalemba Coachlines)
  admin@chibolya.example     (tenant_admin, Chibolya Logistics — no Operator profile)
  platform@miway.example     (platform_admin — sees every organisation)

Log in as a Kalemba user and a Chibolya user in two browser sessions to see
tenant isolation directly: neither can see the other's vehicles, bookings,
freight orders, or financial records.
""")
