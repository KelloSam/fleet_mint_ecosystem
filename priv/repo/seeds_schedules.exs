# ============================================================
# Lusaka Intercity Bus Station — Schedules Seed
# Run with:  mix run priv/repo/seeds_schedules.exs
# Safe to re-run — skips if schedule_code already exists
# ============================================================
alias FleetMint.Repo
alias FleetMint.Fleet.{Route, Operator}
alias FleetMint.Transit.Schedule
import Ecto.Query

get_route  = fn name -> Repo.one(from r in Route,    where: like(r.name, ^"#{name}%"), limit: 1) end
get_op     = fn slug -> Repo.get_by(Operator, slug: slug) end
t          = fn h, m -> ~T[00:00:00] |> Time.add(h * 3600 + m * 60) end
arr        = fn h, m, dur_min ->
               base = h * 60 + m + dur_min
               Time.new!(div(base, 60) |> rem(24), rem(base, 60), 0)
             end

# Format: {route_name_prefix, operator_slug, departure_h, departure_m, seats, days_of_week}
# days_of_week: ~w(mon tue wed thu fri sat sun) or [] means daily

schedules = [

  # ══════════════════════════════════════════════
  # LUSAKA → LIVINGSTONE  (470 km · 5h30 · ZMW 270)
  # ══════════════════════════════════════════════
  {"Lusaka → Livingstone", "mazhandu",    5,  0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Livingstone", "cr-carriers", 6,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Livingstone", "power-tools", 7,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Livingstone", "juldan-motors",8, 0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Livingstone", "mazhandu",   12,  0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Livingstone", "cross-country",13,0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Livingstone", "euro-africa", 14, 0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Livingstone", "ubz",          6, 30,45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Livingstone", "tang-tong",    9,  0,45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Livingstone", "jordan",       7, 30,45, ~w(mon wed fri sat)},
  {"Lusaka → Livingstone", "falcon",       8,  0,45, ~w(mon tue wed thu fri sat sun)},

  # ══════════════════════════════════════════════
  # LUSAKA → CHIPATA  (585 km · 7h · ZMW 310)
  # ══════════════════════════════════════════════
  {"Lusaka → Chipata", "mazhandu",    5,  0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Chipata", "cr-carriers", 5, 30, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Chipata", "shalom",      6,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Chipata", "kobs",        6, 30, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Chipata", "germins",     7,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Chipata", "shadreck",   14,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Chipata", "tang-tong",   7, 30, 45, ~w(mon wed fri sat)},
  {"Lusaka → Chipata", "ubz",         6,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Chipata", "timmy",       8,  0, 45, ~w(mon tue wed thu fri sat sun)},

  # ══════════════════════════════════════════════
  # LUSAKA → NDOLA  (325 km · 4h · ZMW 190)
  # ══════════════════════════════════════════════
  {"Lusaka → Ndola", "mazhandu",     6,  0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Ndola", "cr-carriers",  7,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Ndola", "taqwa",        7, 30, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Ndola", "power-tools",  8,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Ndola", "fedha",        9,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Ndola", "mazhandu",    12,  0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Ndola", "cross-country",13, 0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Ndola", "ubz",          8, 30, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Ndola", "falcon",       9, 30, 45, ~w(mon tue wed thu fri sat sun)},

  # ══════════════════════════════════════════════
  # LUSAKA → KITWE  (395 km · 4h30 · ZMW 230)
  # ══════════════════════════════════════════════
  {"Lusaka → Kitwe", "mazhandu",     6,  0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kitwe", "cr-carriers",  6, 30, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kitwe", "taqwa",        7,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kitwe", "kansanshi",    8,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kitwe", "fedha",       13,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kitwe", "ubz",          7, 30, 45, ~w(mon tue wed thu fri sat sun)},

  # ══════════════════════════════════════════════
  # LUSAKA → KABWE  (140 km · 1h35 · ZMW 90)  — frequent short route
  # ══════════════════════════════════════════════
  {"Lusaka → Kabwe", "mazhandu",     6,  0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kabwe", "cr-carriers",  7,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kabwe", "power-tools",  8,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kabwe", "taqwa",        9,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kabwe", "juldan-motors",10, 0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kabwe", "mazhandu",    11,  0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kabwe", "cross-country",13, 0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kabwe", "cr-carriers", 15,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kabwe", "ubz",         12,  0, 45, ~w(mon tue wed thu fri sat sun)},

  # ══════════════════════════════════════════════
  # LUSAKA → KASAMA  (870 km · 10h · ZMW 440)  — overnight/afternoon
  # ══════════════════════════════════════════════
  {"Lusaka → Kasama", "mazhandu",    17,  0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kasama", "cr-carriers", 18,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kasama", "nkashama",    19,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kasama", "ubz",         16,  0, 45, ~w(mon wed fri sat)},

  # ══════════════════════════════════════════════
  # LUSAKA → SOLWEZI  (600 km · 7h · ZMW 330)
  # ══════════════════════════════════════════════
  {"Lusaka → Solwezi", "kansanshi",  6,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Solwezi", "taqwa",      7,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Solwezi", "mazhandu",   8,  0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Solwezi", "jordan",    14,  0, 45, ~w(mon wed fri)},

  # ══════════════════════════════════════════════
  # LUSAKA → MONGU  (580 km · 7h · ZMW 320)
  # ══════════════════════════════════════════════
  {"Lusaka → Mongu", "western-province-bus", 6,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Mongu", "mazhandu",             7,  0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Mongu", "taonga-tours",          8,  0, 45, ~w(mon wed fri sat)},
  {"Lusaka → Mongu", "ubz",                   6, 30, 45, ~w(mon tue wed thu fri sat)},

  # ══════════════════════════════════════════════
  # LUSAKA → MANSA  (750 km · 9h · ZMW 420)
  # ══════════════════════════════════════════════
  {"Lusaka → Mansa", "likili",       17,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Mansa", "cr-carriers",  18,  0, 45, ~w(mon wed fri sat)},
  {"Lusaka → Mansa", "ubz",          16, 30, 45, ~w(tue thu sat)},

  # ══════════════════════════════════════════════
  # LUSAKA → MPIKA  (650 km · 8h · ZMW 360)
  # ══════════════════════════════════════════════
  {"Lusaka → Mpika", "nkashama",    17,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Mpika", "cr-carriers", 18,  0, 45, ~w(mon wed fri)},

  # ══════════════════════════════════════════════
  # LUSAKA → PETAUKE  (390 km · 5h · ZMW 215)
  # ══════════════════════════════════════════════
  {"Lusaka → Petauke", "kobs",     6,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Petauke", "shalom",   7,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Petauke", "timmy",    8,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Petauke", "tang-tong",6, 30, 45, ~w(mon wed fri sat)},

  # ══════════════════════════════════════════════
  # LUSAKA → LUNDAZI  (680 km · 8h30 · ZMW 380)
  # ══════════════════════════════════════════════
  {"Lusaka → Lundazi", "shalom",   5,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Lundazi", "kobs",     5, 30, 45, ~w(mon wed fri sat)},

  # ══════════════════════════════════════════════
  # LUSAKA → CHOMA  (275 km · 3h15 · ZMW 160)
  # ══════════════════════════════════════════════
  {"Lusaka → Choma", "johansen",    7,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Choma", "cr-carriers", 8,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Choma", "juldan-motors",9, 0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Choma", "cross-country",13,0, 45, ~w(mon tue wed thu fri sat sun)},

  # ══════════════════════════════════════════════
  # LUSAKA → LIVINGSTONE SHORT STOPS
  # ══════════════════════════════════════════════
  {"Lusaka → Kafue",    "cross-country", 7, 0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Mazabuka", "johansen",      7, 0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kapiri Mposhi", "mazhandu", 8, 0, 65, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Kapiri Mposhi", "nkashama", 9, 0, 45, ~w(mon tue wed thu fri sat sun)},

  # ══════════════════════════════════════════════
  # LUSAKA → NCHELENGE  (950 km · 12h · ZMW 510)
  # ══════════════════════════════════════════════
  {"Lusaka → Nchelenge", "likili",  16,  0, 45, ~w(mon wed fri sat)},

  # ══════════════════════════════════════════════
  # LUSAKA → CHINGOLA  (450 km · 5h30 · ZMW 260)
  # ══════════════════════════════════════════════
  {"Lusaka → Chingola", "taqwa",     7,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Chingola", "kansanshi", 8,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Chingola", "fedha",    13,  0, 45, ~w(mon tue wed thu fri sat sun)},

  # ══════════════════════════════════════════════
  # LUSAKA → MFUWE  (630 km · 8h · ZMW 350)
  # ══════════════════════════════════════════════
  {"Lusaka → Mfuwe", "germins",     5,  0, 45, ~w(mon wed fri sat)},
  {"Lusaka → Mfuwe", "shalom",      6,  0, 45, ~w(tue thu sat)},

  # ══════════════════════════════════════════════
  # INTERNATIONAL ROUTES
  # ══════════════════════════════════════════════

  # Harare, Zimbabwe  (750 km · 9h · ZMW 650)
  {"Lusaka → Harare", "euro-africa",  7,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Harare", "jordan",       8,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Harare", "supreme",      7, 30, 45, ~w(mon wed fri sat)},
  {"Lusaka → Harare", "tang-tong",   14,  0, 45, ~w(tue thu sat)},

  # Johannesburg, South Africa  (2000 km · ~24h · ZMW 1300)  — overnight coaches
  {"Lusaka → Johannesburg", "jordan",     16,  0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Johannesburg", "euro-africa",17,  0, 45, ~w(mon wed fri sat)},
  {"Lusaka → Johannesburg", "supreme",    15,  0, 45, ~w(tue thu sat)},

  # Lilongwe, Malawi  (850 km · ZMW 700)
  {"Lusaka → Lilongwe", "euro-africa",   7,  0, 45, ~w(mon wed fri sat)},
  {"Lusaka → Lilongwe", "cr-carriers",   8,  0, 45, ~w(tue thu sat)},

  # Dar es Salaam, Tanzania  (1800 km · ZMW 1100)
  {"Lusaka → Dar es Salaam", "jordan",     15,  0, 45, ~w(mon wed fri)},
  {"Lusaka → Dar es Salaam", "euro-africa",16,  0, 45, ~w(tue thu sat)},

  # ══════════════════════════════════════════════
  # WESTERN PROVINCE
  # ══════════════════════════════════════════════
  {"Lusaka → Kaoma",   "western-province-bus", 6, 0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Mumbwa",  "western-province-bus", 7, 0, 45, ~w(mon tue wed thu fri sat sun)},
  {"Lusaka → Senanga", "western-province-bus",16, 0, 45, ~w(mon wed fri)},

  # ══════════════════════════════════════════════
  # LUAPULA PROVINCE
  # ══════════════════════════════════════════════
  {"Lusaka → Samfya",    "likili", 15, 0, 45, ~w(mon wed fri sat)},
  {"Lusaka → Kawambwa",  "likili", 16, 0, 45, ~w(tue thu sat)},
  {"Lusaka → Nakonde",   "nkashama",17, 0, 45, ~w(mon wed fri)},
  {"Lusaka → Mbala",     "nkashama",17, 30,45, ~w(tue thu sat)},

  # ══════════════════════════════════════════════
  # NORTH-WESTERN PROVINCE
  # ══════════════════════════════════════════════
  {"Lusaka → Kasempa",   "kansanshi", 7, 0, 45, ~w(mon wed fri sat)},
  {"Lusaka → Mwinilunga","kansanshi",16, 0, 45, ~w(mon wed fri)}
]

IO.puts "\n== Seeding Schedules =="

{inserted, skipped, errors} =
  Enum.reduce(schedules, {0, 0, 0}, fn {route_prefix, op_slug, dep_h, dep_m, seats, days}, {ins, skip, err} ->
    route    = get_route.(route_prefix)
    operator = get_op.(op_slug)

    cond do
      is_nil(route) ->
        IO.puts "  ! Route not found: #{route_prefix}"
        {ins, skip, err + 1}

      is_nil(operator) ->
        IO.puts "  ! Operator not found: #{op_slug}"
        {ins, skip, err + 1}

      true ->
        dep_time = t.(dep_h, dep_m)
        est_arr  = arr.(dep_h, dep_m, route.duration)
        code     = "SCH-#{op_slug |> String.upcase() |> String.replace("-", "")}-#{route.id}-#{dep_h}#{String.pad_leading("#{dep_m}", 2, "0")}"

        if Repo.get_by(Schedule, schedule_code: code) do
          {ins, skip + 1, err}
        else
          attrs = %{
            schedule_code:          code,
            departure_time:         dep_time,
            estimated_arrival_time: est_arr,
            fare:                   route.fare,
            available_seats:        seats,
            days_of_week:           days,
            status:                 "active",
            validation_mode:        "static",
            route_id:               route.id,
            operator_id:            operator.id
          }

          case %Schedule{} |> Schedule.changeset(attrs) |> Repo.insert() do
            {:ok, _s} ->
              {ins + 1, skip, err}
            {:error, cs} ->
              IO.puts "  ! Error for #{route_prefix}/#{op_slug} #{dep_h}:#{dep_m} — #{inspect(cs.errors)}"
              {ins, skip, err + 1}
          end
        end
    end
  end)

IO.puts "\n== Done =="
IO.puts "  Inserted: #{inserted}"
IO.puts "  Skipped (already exist): #{skipped}"
IO.puts "  Errors: #{errors}"
IO.puts "\nYou can now select schedules when creating a booking at /bookings/new"
