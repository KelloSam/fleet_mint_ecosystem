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
alias FleetMint.Transport.Routes.Route
alias FleetMint.HR
alias FleetMint.Finance
alias FleetMint.Cargo
alias FleetMint.Administration

dev_password = "DevPassword123!"

# Shared password for the 4 demo-walkthrough accounts only (platform admin,
# Director, Operations Manager, Cashier) — requested as "admin@fleetmint",
# adjusted to satisfy User.password_changeset's own rules (12+ chars, upper +
# lower + digit), which apply to every login and were not relaxed. Every
# other seed user (Chibolya's admin, the generic platform@miway.example)
# keeps dev_password above, unchanged.
demo_password = "Admin@Fleetmint1"

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
    password: demo_password,
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
    password: demo_password,
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
    password: demo_password,
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

IO.puts("\n== FleetMint dev seed: Tenant 3+ — fictional multi-operator public-booking catalogue ==")

# ---------------------------------------------------------------------------
# WHY THIS EXISTS
# The public booking flow (/book) needs more than one operator to
# demonstrate itself at all — comparing companies, routes, and fares is the
# entire point of that feature. The dataset that used to fill this role
# (priv/repo/seeds_intercity.exs + seeds_operator_routes.exs, both deleted
# in the 2026-08-15 wipe-recovery commit) turned out, on investigation, to
# be built from real, currently-operating Zambian bus companies — Mazhandu,
# CR Carriers, Power Tools, Shalom, Juldan Motors, Euro Africa, Kobs,
# Taqwa, Likili, and Falcon all check out as real businesses, not invented
# demo names; the remaining names in that set are unverified but follow
# the identical pattern. Restoring it verbatim would repeat, at roughly
# 20x scale, the exact problem already fixed for Mazhandu (Architecture
# Decision Queue item 9): mixing a real business's identity into public
# dev/demo data with no governance around it.
#
# Everything below is invented instead. Route geography (corridors,
# distances, durations, base fares) is reused from that recovered
# dataset — that part is public road infrastructure, not anyone's company
# identity — but every operator name, slug, contact, branch, and terminal
# here is fictional. Contact emails use the reserved .example TLD (RFC
# 2606), the same convention already used for Kalemba/Chibolya above, to
# make the non-real status unambiguous at a glance.
#
# Do not add Mazhandu, or any other real operator, here or anywhere in
# this file. A real pilot organisation's data goes through
# docs/pilot/PILOT_DEFINITION.md, never through seeds.exs.
# ---------------------------------------------------------------------------

get_or_create_route = fn name, start_loc, end_loc, distance, duration, fare ->
  case Repo.get_by(Route, name: name) do
    nil ->
      {:ok, route} =
        Routes.create_route(%{
          name: name,
          status: "active",
          start_location: start_loc,
          end_location: end_loc,
          distance: distance,
          duration: duration,
          fare: fare
        })

      route

    route ->
      route
  end
end

demo_routes = %{
  # Reuses Kalemba's existing two routes rather than duplicating them —
  # deliberate: operators genuinely compete on the same physical corridors.
  "lsk-liv" =>
    get_or_create_route.("Lusaka - Livingstone", "Lusaka", "Livingstone", "470.0", 330, "270.00"),
  "lsk-ndl" => get_or_create_route.("Lusaka - Ndola", "Lusaka", "Ndola", "320.0", 240, "150.00"),
  "lsk-ktw" => get_or_create_route.("Lusaka - Kitwe", "Lusaka", "Kitwe", "360.0", 270, "170.00"),
  "lsk-kbw" => get_or_create_route.("Lusaka - Kabwe", "Lusaka", "Kabwe", "140.0", 95, "90.00"),
  "lsk-chp" => get_or_create_route.("Lusaka - Chipata", "Lusaka", "Chipata", "585.0", 420, "310.00"),
  "lsk-ksm" => get_or_create_route.("Lusaka - Kasama", "Lusaka", "Kasama", "860.0", 600, "420.00"),
  "lsk-mng" => get_or_create_route.("Lusaka - Mongu", "Lusaka", "Mongu", "600.0", 480, "350.00"),
  "lsk-swz" => get_or_create_route.("Lusaka - Solwezi", "Lusaka", "Solwezi", "600.0", 480, "350.00"),
  "lsk-chm" => get_or_create_route.("Lusaka - Choma", "Lusaka", "Choma", "275.0", 195, "160.00"),
  "lsk-mzb" => get_or_create_route.("Lusaka - Mazabuka", "Lusaka", "Mazabuka", "160.0", 115, "110.00"),
  "lsk-mns" => get_or_create_route.("Lusaka - Mansa", "Lusaka", "Mansa", "800.0", 570, "400.00"),
  "lsk-kpm" =>
    get_or_create_route.("Lusaka - Kapiri Mposhi", "Lusaka", "Kapiri Mposhi", "200.0", 135, "120.00"),
  "lsk-ptk" => get_or_create_route.("Lusaka - Petauke", "Lusaka", "Petauke", "450.0", 330, "240.00"),
  "lsk-srj" => get_or_create_route.("Lusaka - Serenje", "Lusaka", "Serenje", "280.0", 195, "160.00"),
  "ndl-ktw" => get_or_create_route.("Ndola - Kitwe", "Ndola", "Kitwe", "60.0", 50, "40.00"),
  "lsk-chg" => get_or_create_route.("Lusaka - Chongwe", "Lusaka", "Chongwe", "45.0", 50, "35.00")
}

frequency_days = fn
  :daily -> ~w(mon tue wed thu fri sat sun)
  :weekdays -> ~w(mon tue wed thu fri)
  :three_weekly -> ~w(mon wed fri)
  :weekend -> ~w(fri sat sun)
end

tier_multiplier = fn
  :budget -> Decimal.new("0.85")
  :standard -> Decimal.new("1.00")
  :premium -> Decimal.new("1.25")
  :shuttle -> Decimal.new("1.00")
end

tier_route_type = fn
  :shuttle -> "urban"
  _ -> "intercity"
end

tier_amenities = fn
  :premium -> ~w(ac wifi usb_charging reclining_seats)
  :standard -> ~w(ac usb_charging)
  :budget -> ~w(ac)
  :shuttle -> []
end

driver_first_names = ~w(Chanda Mutale Bwalya Mumba Phiri Banda Tembo Lungu Sakala Mwansa Chola Kunda Nyirenda Kabwe Musonda)
driver_last_names = ~w(Chirwa Mwape Katongo Mubita Simfukwe Chibwe Mulenga Kaonga Silavwe Habanyama Chishimba Zimba)

fictional_operators = [
  %{
    name: "Baobab Coachways",
    slug: "baobab-coachways",
    tagline: "Zambia's Premium Long-Distance Line",
    phone: "+260 97 601 0001",
    email: "info@baobabcoachways.example",
    color: "#b45309",
    branches: [{"Lusaka", "Lusaka Main Depot"}, {"Livingstone", "Livingstone Depot"}],
    fleet_size: 5,
    capacity: 65,
    tier: :premium,
    frequency: :daily,
    routes: ~w(lsk-liv lsk-ktw lsk-ndl lsk-chp lsk-ksm)
  },
  %{
    name: "Miombo Express",
    slug: "miombo-express",
    tagline: "Fast, Direct, Every Day",
    phone: "+260 97 601 0002",
    email: "info@miomboexpress.example",
    color: "#1d4ed8",
    branches: [{"Lusaka", "Lusaka Depot"}, {"Ndola", "Ndola Depot"}],
    fleet_size: 4,
    capacity: 60,
    tier: :standard,
    frequency: :daily,
    routes: ~w(lsk-liv lsk-ndl lsk-ktw lsk-kbw)
  },
  %{
    name: "Zambezi Sunrise Travel",
    slug: "zambezi-sunrise-travel",
    tagline: "Weekend Getaways to the Falls",
    phone: "+260 97 601 0003",
    email: "info@zambezisunrise.example",
    color: "#0891b2",
    branches: [{"Lusaka", "Lusaka Depot"}, {"Livingstone", "Livingstone Depot"}],
    fleet_size: 3,
    capacity: 50,
    tier: :standard,
    frequency: :weekend,
    routes: ~w(lsk-liv lsk-chm lsk-mzb)
  },
  %{
    name: "Chikwanda Transit",
    slug: "chikwanda-transit",
    tagline: "Zambia's Affordable Way to Travel",
    phone: "+260 97 601 0004",
    email: "info@chikwandatransit.example",
    color: "#374151",
    branches: [{"Lusaka", "Lusaka Depot"}],
    fleet_size: 3,
    capacity: 65,
    tier: :budget,
    frequency: :daily,
    routes: ~w(lsk-liv lsk-ndl lsk-ktw lsk-chp)
  },
  %{
    name: "Copperbelt Connect",
    slug: "copperbelt-connect",
    tagline: "Linking the Copperbelt, Daily",
    phone: "+260 97 601 0005",
    email: "info@copperbeltconnect.example",
    color: "#15803d",
    branches: [{"Ndola", "Ndola Depot"}, {"Kitwe", "Kitwe Depot"}],
    fleet_size: 3,
    capacity: 45,
    tier: :standard,
    frequency: :daily,
    routes: ~w(lsk-ndl lsk-ktw ndl-ktw)
  },
  %{
    name: "Luangwa Valley Coaches",
    slug: "luangwa-valley-coaches",
    tagline: "Eastern Province Specialists",
    phone: "+260 97 601 0006",
    email: "info@luangwavalleycoaches.example",
    color: "#92400e",
    branches: [{"Lusaka", "Lusaka Depot"}, {"Chipata", "Chipata Depot"}],
    fleet_size: 2,
    capacity: 45,
    tier: :standard,
    frequency: :weekdays,
    routes: ~w(lsk-chp lsk-ptk)
  },
  %{
    name: "Ndeke Route Services",
    slug: "ndeke-route-services",
    tagline: "Reliable, Affordable, Nationwide",
    phone: "+260 97 601 0007",
    email: "info@ndekeroutes.example",
    color: "#6d28d9",
    branches: [{"Lusaka", "Lusaka Depot"}],
    fleet_size: 3,
    capacity: 65,
    tier: :budget,
    frequency: :three_weekly,
    routes: ~w(lsk-kbw lsk-kpm lsk-srj)
  },
  %{
    name: "Kafubu Shuttle Services",
    slug: "kafubu-shuttle-services",
    tagline: "Copperbelt Town-to-Town, Every Hour",
    phone: "+260 97 601 0008",
    email: "info@kafubushuttle.example",
    color: "#0d9488",
    branches: [{"Ndola", "Ndola Depot"}],
    fleet_size: 2,
    capacity: 18,
    tier: :shuttle,
    frequency: :daily,
    routes: ~w(ndl-ktw)
  },
  %{
    name: "Chilanga Crossroads Travel",
    slug: "chilanga-crossroads-travel",
    tagline: "Southern Corridor, Done Right",
    phone: "+260 97 601 0009",
    email: "info@chilangacrossroads.example",
    color: "#166534",
    branches: [{"Lusaka", "Lusaka Depot"}, {"Choma", "Choma Depot"}],
    fleet_size: 3,
    capacity: 50,
    tier: :standard,
    frequency: :daily,
    routes: ~w(lsk-chm lsk-mzb lsk-liv)
  },
  %{
    name: "Bemba Heritage Travel",
    slug: "bemba-heritage-travel",
    tagline: "Proudly Northern Province",
    phone: "+260 97 601 0010",
    email: "info@bembaheritage.example",
    color: "#be185d",
    branches: [{"Lusaka", "Lusaka Depot"}],
    fleet_size: 2,
    capacity: 50,
    tier: :standard,
    frequency: :three_weekly,
    routes: ~w(lsk-ksm lsk-mns)
  },
  %{
    name: "Lozi Plains Motorlines",
    slug: "lozi-plains-motorlines",
    tagline: "Your Way West",
    phone: "+260 97 601 0011",
    email: "info@loziplains.example",
    color: "#854d0e",
    branches: [{"Lusaka", "Lusaka Depot"}, {"Mongu", "Mongu Depot"}],
    fleet_size: 2,
    capacity: 50,
    tier: :standard,
    frequency: :weekdays,
    routes: ~w(lsk-mng)
  },
  %{
    name: "Nsingo Travel & Tours",
    slug: "nsingo-travel-tours",
    tagline: "Eastern Province, Comfortably",
    phone: "+260 97 601 0012",
    email: "info@nsingotravel.example",
    color: "#be5504",
    branches: [{"Lusaka", "Lusaka Depot"}],
    fleet_size: 2,
    capacity: 45,
    tier: :standard,
    frequency: :weekend,
    routes: ~w(lsk-chp lsk-ptk)
  },
  %{
    name: "Chongwe Valley Shuttle",
    slug: "chongwe-valley-shuttle",
    tagline: "Lusaka's Nearest Neighbour, Fast",
    phone: "+260 97 601 0013",
    email: "info@chongwevalleyshuttle.example",
    color: "#7c3aed",
    branches: [{"Lusaka", "Lusaka Depot"}],
    fleet_size: 1,
    capacity: 14,
    tier: :shuttle,
    frequency: :daily,
    routes: ~w(lsk-chg)
  },
  %{
    name: "Katuba Crossroads Transit",
    slug: "katuba-crossroads-transit",
    tagline: "Nationwide, No Frills",
    phone: "+260 97 601 0014",
    email: "info@katubacrossroads.example",
    color: "#312e81",
    branches: [{"Lusaka", "Lusaka Depot"}],
    fleet_size: 4,
    capacity: 65,
    tier: :budget,
    frequency: :daily,
    routes: ~w(lsk-liv lsk-ndl lsk-ktw lsk-chp lsk-kbw)
  },
  %{
    name: "Mumbwa Plains Travel",
    slug: "mumbwa-plains-travel",
    tagline: "Central Province Connector",
    phone: "+260 97 601 0015",
    email: "info@mumbwaplains.example",
    color: "#78350f",
    branches: [{"Lusaka", "Lusaka Depot"}],
    fleet_size: 2,
    capacity: 45,
    tier: :standard,
    frequency: :weekdays,
    routes: ~w(lsk-kbw lsk-kpm)
  },
  %{
    name: "Solwezi Ridge Coaches",
    slug: "solwezi-ridge-coaches",
    tagline: "North-Western Province Route Specialists",
    phone: "+260 97 601 0016",
    email: "info@solweziridge.example",
    color: "#1e40af",
    branches: [{"Lusaka", "Lusaka Depot"}, {"Solwezi", "Solwezi Depot"}],
    fleet_size: 2,
    capacity: 50,
    tier: :standard,
    frequency: :three_weekly,
    routes: ~w(lsk-swz lsk-ktw)
  },
  %{
    name: "Siavonga Lakeside Travel",
    slug: "siavonga-lakeside-travel",
    tagline: "Weekend Trips to Lake Kariba",
    phone: "+260 97 601 0017",
    email: "info@siavongalakeside.example",
    color: "#0369a1",
    branches: [{"Lusaka", "Lusaka Depot"}],
    fleet_size: 2,
    capacity: 45,
    tier: :standard,
    frequency: :weekend,
    routes: ~w(lsk-chm lsk-mzb)
  },
  %{
    name: "Mutanda Trailblazers",
    slug: "mutanda-trailblazers",
    tagline: "Premium Travel to the North-West",
    phone: "+260 97 601 0018",
    email: "info@mutandatrailblazers.example",
    color: "#9a3412",
    branches: [{"Lusaka", "Lusaka Depot"}, {"Solwezi", "Solwezi Depot"}],
    fleet_size: 4,
    capacity: 60,
    tier: :premium,
    frequency: :daily,
    routes: ~w(lsk-swz lsk-ktw lsk-ndl)
  }
]

fictional_operators
|> Enum.with_index()
|> Enum.each(fn {op, op_idx} ->
  {:ok, operator} =
    Fleet.create_operator(%{
      name: op.name,
      slug: op.slug,
      tagline: op.tagline,
      contact_phone: op.phone,
      contact_email: op.email,
      color: op.color
    })

  Enum.each(op.branches, fn {city, branch_name} ->
    {:ok, branch} =
      Fleet.create_branch(%{
        name: branch_name,
        city: city,
        organisation_id: operator.organisation_id
      })

    {:ok, _terminal} =
      Fleet.create_terminal(%{
        name: "#{city} Boarding Point",
        address: "#{city} Bus Station",
        branch_id: branch.id
      })
  end)

  drivers =
    Enum.map(1..min(op.fleet_size, 3), fn n ->
      {:ok, driver} =
        HR.create_driver(%{
          name:
            "#{Enum.at(driver_first_names, rem(n * 7, length(driver_first_names)))} " <>
              "#{Enum.at(driver_last_names, rem(n * 11, length(driver_last_names)))}",
          phone: "+260 96 #{700 + op_idx} #{String.pad_leading(Integer.to_string(n), 4, "0")}",
          license_number: "DL-#{String.upcase(op.slug)}-#{n}",
          license_expiry: Date.add(Date.utc_today(), 365),
          daily_rate: "300.00",
          date_hired: ~D[2024-01-01],
          status: "active",
          organisation_id: operator.organisation_id
        })

      driver
    end)

  vehicles =
    Enum.map(1..op.fleet_size, fn n ->
      {:ok, vehicle} =
        Fleet.create_vehicle(%{
          "registration_number" =>
            "#{String.upcase(String.slice(op.slug, 0, 3))} #{2000 + op_idx * 10 + n}",
          "make" => "Yutong",
          "model" => "ZK6122",
          "year" => "2022",
          "vehicle_type" => "bus",
          "status" => "active",
          "organisation_id" => operator.organisation_id,
          "bus_profile" => %{
            "seating_capacity" => op.capacity,
            "route_type" => tier_route_type.(op.tier),
            "amenities" => tier_amenities.(op.tier)
          }
        })

      vehicle
    end)

  days = frequency_days.(op.frequency)
  multiplier = tier_multiplier.(op.tier)

  op.routes
  |> Enum.with_index()
  |> Enum.each(fn {route_key, idx} ->
    route = Map.fetch!(demo_routes, route_key)
    Routes.add_route_to_operator(operator, route)

    vehicle = Enum.at(vehicles, rem(idx, length(vehicles)))
    driver = Enum.at(drivers, rem(idx, length(drivers)))

    dep_hour = 5 + rem(idx * 2, 13)
    dep_min = if rem(idx, 2) == 0, do: 0, else: 30
    departure_time = Time.new!(dep_hour, dep_min, 0)

    fare = Decimal.mult(route.fare, multiplier) |> Decimal.round(2)

    {:ok, _schedule} =
      Trips.create_schedule(%{
        departure_time: departure_time,
        estimated_arrival_time: Time.add(departure_time, route.duration * 60),
        days_of_week: days,
        fare: fare,
        available_seats: op.capacity,
        status: "active",
        route_id: route.id,
        operator_id: operator.id,
        vehicle_id: vehicle.id,
        driver_id: driver.id
      })
  end)

  IO.puts(
    "  + #{op.name}: #{length(op.branches)} branch(es), #{op.fleet_size} vehicle(s), " <>
      "#{length(op.routes)} route(s), #{op.frequency} schedule"
  )
end)

IO.puts(
  "Fictional catalogue: #{length(fictional_operators)} operators, all with routes, schedules, " <>
    "branches and terminals — no login users (public booking needs none). All entirely " <>
    "invented; see the block comment above for why real operator names were rejected."
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

{:ok, _kellosaa_admin} =
  Users.create_user(%{
    username: "kellosaa_admin",
    email: "kellosaa30@gmail.com",
    password: demo_password,
    role: "platform_admin",
    full_name: "Kellosaa",
    active: true,
    organisation_id: nil
  })

IO.puts("Platform admin: kellosaa30@gmail.com — personal login, same tier as platform@miway.example.")

IO.puts("""

== Dev seed complete ==

The 4 demo-walkthrough accounts share one password: #{demo_password}
  kellosaa30@gmail.com    (platform_admin — sees every organisation)
  admin@kalemba.example   (tenant_admin "Director", Kalemba Coachlines)
  manager@kalemba.example (manager "Operations Manager", Kalemba Coachlines)
  cashier@kalemba.example (cashier "Cashier", Kalemba Coachlines)

Every other seed user shares a separate password: #{dev_password}
  admin@chibolya.example  (tenant_admin, Chibolya Logistics — no Operator profile)
  platform@miway.example  (platform_admin — sees every organisation)

Log in as a Kalemba user and a Chibolya user in two browser sessions to see
tenant isolation directly: neither can see the other's vehicles, bookings,
freight orders, or financial records.

The public booking flow (/book) additionally lists #{length(fictional_operators)}
fictional bus operators — Baobab Coachways, Miombo Express, and others —
with their own routes and schedules. These have no login users and are not
part of tenant-isolation testing; they exist purely so /book has more than
one company to browse and compare. See the block comment above the
fictional-operator section for why the previous 23-company dataset was not
restored as-is.
""")
