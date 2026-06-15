# ============================================================
# Lusaka Intercity Bus Station — Operators & Routes Seed
# Run with:  mix run priv/repo/seeds_intercity.exs
# Safe to re-run — uses on_conflict: :nothing
# ============================================================
alias FleetMint.Repo
alias FleetMint.Fleet.{Operator, Route}
import Ecto.Changeset

# ── ROUTES (shared across all operators) ─────────────────────────────────────
# Format: {name, start, end, stops, distance_km, duration_mins, fare_zmw, desc}

routes = [
  # ── SOUTHERN CORRIDOR (Great North Road South / T1) ─────────────────────
  {
    "Lusaka → Livingstone",
    "Lusaka", "Livingstone",
    ["Kafue", "Mazabuka", "Monze", "Choma", "Kalomo"],
    470, 330, 270.0,
    "T1 Great North Road South via Kafue, Choma. Gateway to Victoria Falls."
  },
  {
    "Lusaka → Choma",
    "Lusaka", "Choma",
    ["Kafue", "Mazabuka", "Monze"],
    275, 195, 160.0,
    "T1 via Kafue and Mazabuka."
  },
  {
    "Lusaka → Mazabuka",
    "Lusaka", "Mazabuka",
    ["Kafue"],
    160, 115, 110.0,
    "T1 via Kafue."
  },
  {
    "Lusaka → Kafue",
    "Lusaka", "Kafue",
    [],
    45, 40, 40.0,
    "Short run on T1."
  },
  {
    "Lusaka → Monze",
    "Lusaka", "Monze",
    ["Kafue", "Mazabuka"],
    225, 165, 135.0,
    "T1 via Mazabuka."
  },
  {
    "Lusaka → Kalomo",
    "Lusaka", "Kalomo",
    ["Kafue", "Mazabuka", "Monze", "Choma"],
    415, 295, 230.0,
    "T1 via Choma before Livingstone."
  },

  # ── NORTHERN CORRIDOR (Great North Road T2) ──────────────────────────────
  {
    "Lusaka → Kabwe",
    "Lusaka", "Kabwe",
    [],
    140, 95, 90.0,
    "T2 Great North Road. First major stop north of Lusaka."
  },
  {
    "Lusaka → Kapiri Mposhi",
    "Lusaka", "Kapiri Mposhi",
    ["Kabwe"],
    200, 135, 120.0,
    "T2 via Kabwe. TAZARA railway junction town."
  },
  {
    "Lusaka → Mkushi",
    "Lusaka", "Mkushi",
    ["Kabwe", "Kapiri Mposhi"],
    280, 195, 160.0,
    "T2 via Kapiri Mposhi."
  },
  {
    "Lusaka → Serenje",
    "Lusaka", "Serenje",
    ["Kabwe", "Kapiri Mposhi", "Mkushi"],
    420, 295, 230.0,
    "T2 via Mkushi. Junction for Bangweulu."
  },
  {
    "Lusaka → Mpika",
    "Lusaka", "Mpika",
    ["Kabwe", "Kapiri Mposhi", "Serenje"],
    650, 460, 360.0,
    "T2 via Serenje. Gateway to North Luangwa."
  },
  {
    "Lusaka → Kasama",
    "Lusaka", "Kasama",
    ["Kabwe", "Kapiri Mposhi", "Serenje", "Mpika"],
    870, 615, 440.0,
    "T2 full northern run via Mpika. Northern Province capital."
  },
  {
    "Lusaka → Mbala",
    "Lusaka", "Mbala",
    ["Kabwe", "Kapiri Mposhi", "Serenje", "Mpika", "Kasama"],
    1100, 780, 570.0,
    "T2 to the far north near Lake Tanganyika."
  },
  {
    "Lusaka → Nakonde",
    "Lusaka", "Nakonde",
    ["Kabwe", "Kapiri Mposhi", "Serenje", "Mpika", "Kasama", "Mbala"],
    1250, 890, 640.0,
    "T2 to Tanzania border."
  },

  # ── LUAPULA / NORTHERN LAKES ─────────────────────────────────────────────
  {
    "Lusaka → Mansa",
    "Lusaka", "Mansa",
    ["Kabwe", "Kapiri Mposhi", "Serenje", "Samfya"],
    750, 540, 420.0,
    "Via Serenje and Samfya. Luapula Province capital."
  },
  {
    "Lusaka → Samfya",
    "Lusaka", "Samfya",
    ["Kabwe", "Kapiri Mposhi", "Serenje"],
    600, 435, 330.0,
    "Via Serenje to Lake Bangweulu."
  },
  {
    "Lusaka → Nchelenge",
    "Lusaka", "Nchelenge",
    ["Kabwe", "Kapiri Mposhi", "Serenje", "Mansa"],
    950, 690, 510.0,
    "Via Mansa to Lake Mweru."
  },
  {
    "Lusaka → Kawambwa",
    "Lusaka", "Kawambwa",
    ["Kabwe", "Kapiri Mposhi", "Serenje", "Mansa"],
    870, 630, 470.0,
    "Via Mansa to Luapula north."
  },

  # ── COPPERBELT CORRIDOR ───────────────────────────────────────────────────
  {
    "Lusaka → Ndola",
    "Lusaka", "Ndola",
    ["Kabwe", "Kapiri Mposhi"],
    325, 230, 190.0,
    "T2 to Copperbelt. Zambia's second city."
  },
  {
    "Lusaka → Kitwe",
    "Lusaka", "Kitwe",
    ["Kabwe", "Kapiri Mposhi", "Ndola"],
    395, 280, 230.0,
    "T2 via Ndola. Major Copperbelt city."
  },
  {
    "Lusaka → Chingola",
    "Lusaka", "Chingola",
    ["Kabwe", "Kapiri Mposhi", "Ndola", "Kitwe"],
    450, 320, 260.0,
    "T2 via Kitwe to deep Copperbelt."
  },
  {
    "Lusaka → Chililabombwe",
    "Lusaka", "Chililabombwe",
    ["Kabwe", "Kapiri Mposhi", "Ndola", "Kitwe", "Chingola"],
    475, 340, 280.0,
    "T2 to DRC border town."
  },
  {
    "Lusaka → Mufulira",
    "Lusaka", "Mufulira",
    ["Kabwe", "Kapiri Mposhi", "Ndola", "Kitwe"],
    420, 300, 240.0,
    "Via Kitwe to Mufulira."
  },
  {
    "Lusaka → Luanshya",
    "Lusaka", "Luanshya",
    ["Kabwe", "Kapiri Mposhi", "Ndola"],
    360, 255, 210.0,
    "Via Ndola to Luanshya."
  },

  # ── NORTH-WESTERN PROVINCE ────────────────────────────────────────────────
  {
    "Lusaka → Solwezi",
    "Lusaka", "Solwezi",
    ["Kabwe", "Kapiri Mposhi", "Ndola", "Kitwe", "Chingola"],
    600, 430, 330.0,
    "Via Copperbelt to North-Western Province capital."
  },
  {
    "Lusaka → Kasempa",
    "Lusaka", "Kasempa",
    ["Kabwe", "Kapiri Mposhi", "Ndola", "Solwezi"],
    700, 505, 390.0,
    "Via Solwezi to Kasempa."
  },
  {
    "Lusaka → Mwinilunga",
    "Lusaka", "Mwinilunga",
    ["Kabwe", "Kapiri Mposhi", "Ndola", "Solwezi", "Kasempa"],
    930, 670, 510.0,
    "Far north-west to Angola border area."
  },

  # ── GREAT EAST ROAD (T4) ─────────────────────────────────────────────────
  {
    "Lusaka → Luangwa",
    "Lusaka", "Luangwa",
    [],
    130, 100, 85.0,
    "T4 Great East Road. Luangwa Bridge area."
  },
  {
    "Lusaka → Petauke",
    "Lusaka", "Petauke",
    ["Luangwa"],
    390, 285, 215.0,
    "T4 via Luangwa."
  },
  {
    "Lusaka → Katete",
    "Lusaka", "Katete",
    ["Luangwa", "Petauke"],
    490, 355, 265.0,
    "T4 via Petauke."
  },
  {
    "Lusaka → Chipata",
    "Lusaka", "Chipata",
    ["Luangwa", "Petauke", "Katete"],
    585, 425, 310.0,
    "T4 full Great East Road. Eastern Province capital. Near Malawi border."
  },
  {
    "Lusaka → Lundazi",
    "Lusaka", "Lundazi",
    ["Luangwa", "Petauke", "Chipata"],
    680, 495, 380.0,
    "T4 via Chipata north. Remote Eastern Province."
  },
  {
    "Lusaka → Mfuwe",
    "Lusaka", "Mfuwe",
    ["Luangwa", "Petauke", "Chipata"],
    630, 460, 350.0,
    "T4 to South Luangwa National Park gate."
  },
  {
    "Lusaka → Nyimba",
    "Lusaka", "Nyimba",
    ["Luangwa"],
    280, 205, 160.0,
    "T4 between Luangwa and Petauke."
  },

  # ── WESTERN PROVINCE ─────────────────────────────────────────────────────
  {
    "Lusaka → Mongu",
    "Lusaka", "Mongu",
    ["Mumbwa", "Kaoma"],
    580, 420, 320.0,
    "M9 via Mumbwa and Kaoma. Western Province capital on the Zambezi."
  },
  {
    "Lusaka → Mumbwa",
    "Lusaka", "Mumbwa",
    [],
    155, 110, 100.0,
    "M9 western corridor. Gateway to Kafue National Park."
  },
  {
    "Lusaka → Kaoma",
    "Lusaka", "Kaoma",
    ["Mumbwa"],
    440, 315, 250.0,
    "M9 via Mumbwa to Western Province."
  },
  {
    "Lusaka → Senanga",
    "Lusaka", "Senanga",
    ["Mumbwa", "Kaoma", "Mongu"],
    670, 485, 380.0,
    "M9 via Mongu deeper into Western Province."
  },
  {
    "Lusaka → Sesheke",
    "Lusaka", "Sesheke",
    ["Mumbwa", "Kaoma", "Mongu", "Senanga"],
    800, 580, 440.0,
    "M9 to Namibia/Botswana border area via Mongu."
  },

  # ── SOUTHERN PROVINCE BRANCH ─────────────────────────────────────────────
  {
    "Lusaka → Siavonga",
    "Lusaka", "Siavonga",
    [],
    180, 130, 120.0,
    "T4 south to Lake Kariba / Siavonga."
  },
  {
    "Lusaka → Gwembe",
    "Lusaka", "Gwembe",
    [],
    200, 145, 130.0,
    "South to Gwembe Valley."
  },

  # ── CROSS-BORDER ROUTES ───────────────────────────────────────────────────
  {
    "Lusaka → Harare (Zimbabwe)",
    "Lusaka", "Harare, Zimbabwe",
    ["Kafue", "Mazabuka", "Livingstone", "Victoria Falls"],
    750, 545, 650.0,
    "International via Livingstone/Vic Falls border crossing."
  },
  {
    "Lusaka → Lilongwe (Malawi)",
    "Lusaka", "Lilongwe, Malawi",
    ["Petauke", "Chipata", "Mchinji Border"],
    850, 620, 700.0,
    "International T4 via Chipata then Mchinji border."
  },
  {
    "Lusaka → Dar es Salaam (Tanzania)",
    "Lusaka", "Dar es Salaam, Tanzania",
    ["Kabwe", "Kapiri Mposhi", "Mpika", "Kasama", "Nakonde", "Tunduma"],
    1800, 1300, 1100.0,
    "International via Great North Road and Nakonde/Tunduma border."
  },
  {
    "Lusaka → Johannesburg (South Africa)",
    "Lusaka", "Johannesburg, South Africa",
    ["Kafue", "Livingstone", "Victoria Falls", "Bulawayo", "Beitbridge"],
    2000, 1440, 1300.0,
    "International via Livingstone and Zimbabwe."
  },
  {
    "Lusaka → Lubumbashi (DRC)",
    "Lusaka", "Lubumbashi, DRC",
    ["Kabwe", "Ndola", "Kitwe", "Chingola", "Chililabombwe"],
    650, 475, 580.0,
    "International via Chililabombwe/Kasumbalesa border."
  }
]

IO.puts "\n== Seeding Routes =="
{inserted_routes, skipped_routes} =
  Enum.reduce(routes, {0, 0}, fn {name, start_loc, end_loc, stops, dist, dur, fare, desc}, {ins, skip} ->
    attrs = %{
      name: name,
      start_location: start_loc,
      end_location: end_loc,
      stops: stops,
      distance: Decimal.new("#{dist}"),
      duration: dur,
      fare: Decimal.new("#{fare}"),
      status: "active",
      description: desc
    }
    if Repo.get_by(Route, name: name) do
      {ins, skip + 1}
    else
      changeset = Route.changeset(%Route{}, attrs)
      case Repo.insert(changeset) do
        {:ok, _}            -> {ins + 1, skip}
        {:error, cs}        ->
          IO.puts "  ERROR #{name}: #{inspect(cs.errors)}"
          {ins, skip + 1}
      end
    end
  end)

IO.puts "  Inserted: #{inserted_routes}  Skipped (already exist): #{skipped_routes}"


# ── OPERATORS (BUS COMPANIES) ─────────────────────────────────────────────────
# Format: {name, slug, tagline, phone, email, color}

operators = [
  {
    "Mazhandu Family Bus Services",
    "mazhandu",
    "Zambia's Most Trusted Long-Distance Bus",
    "+260 211 222 701",
    "info@mazhandufbs.com",
    "#dc2626"   # red
  },
  {
    "CR Carriers",
    "cr-carriers",
    "Reliable Transport Since 1972",
    "+260 211 225 900",
    "crcarriers@zamtel.zm",
    "#15803d"   # green
  },
  {
    "Power Tools Bus Service",
    "power-tools",
    "Comfort & Speed Across Zambia",
    "+260 977 800 100",
    "info@powertoolsbus.zm",
    "#1d4ed8"   # blue
  },
  {
    "Shalom Bus Services",
    "shalom",
    "Safe Journeys, Every Time",
    "+260 977 123 456",
    nil,
    "#7c3aed"   # purple
  },
  {
    "Juldan Motors",
    "juldan-motors",
    "Your Road, Our Commitment",
    "+260 211 231 400",
    "juldan@zamtel.zm",
    "#0369a1"   # sky blue
  },
  {
    "Euro Africa Bus Services",
    "euro-africa",
    "Connecting Zambia to the World",
    "+260 977 300 200",
    "euroafrica@gmail.com",
    "#0891b2"   # cyan
  },
  {
    "Germins Bus Services",
    "germins",
    "Eastern Province Specialists",
    "+260 977 456 789",
    nil,
    "#92400e"   # amber/brown
  },
  {
    "Kobs Bus Services",
    "kobs",
    "Great East Road Experts",
    "+260 966 100 200",
    nil,
    "#065f46"   # dark green
  },
  {
    "Taqwa Bus Services",
    "taqwa",
    "Northern & Copperbelt Routes",
    "+260 977 500 600",
    nil,
    "#1e40af"   # dark blue
  },
  {
    "Likili Transport",
    "likili",
    "Serving Luapula Province",
    "+260 977 700 800",
    nil,
    "#0f766e"   # teal
  },
  {
    "Kansanshi Bus Services",
    "kansanshi",
    "North-Western Province Route Specialists",
    "+260 977 900 100",
    nil,
    "#b45309"   # amber
  },
  {
    "Fedha Bus Services",
    "fedha",
    "Copperbelt & Northern Routes",
    "+260 966 200 300",
    nil,
    "#6d28d9"   # violet
  },
  {
    "Timmy Bus Services",
    "timmy",
    "Affordable Eastern Province Travel",
    "+260 966 400 500",
    nil,
    "#0d9488"   # teal
  },
  {
    "Johansen Bus Services",
    "johansen",
    "Southern Corridor Specialists",
    "+260 977 600 700",
    nil,
    "#be185d"   # pink
  },
  {
    "Cross Country Bus Services",
    "cross-country",
    "Nationwide Coverage",
    "+260 211 228 500",
    "crosscountry@zamtel.zm",
    "#374151"   # gray
  },
  {
    "Nkashama Bus Services",
    "nkashama",
    "Northern Province Route Specialists",
    "+260 977 800 900",
    nil,
    "#166534"   # dark green
  },
  {
    "Shadreck Bus Services",
    "shadreck",
    "Eastern Province — Affordable & Reliable",
    "+260 966 600 700",
    nil,
    "#9a3412"   # orange/brown
  },
  {
    "Taonga Tours & Travel",
    "taonga-tours",
    "Tourism & Long Distance Travel",
    "+260 977 200 300",
    "taonga@tours.zm",
    "#be5504"   # orange
  },
  {
    "Western Province Bus Services",
    "western-province-bus",
    "Connecting Lusaka to the West",
    "+260 966 800 900",
    nil,
    "#854d0e"   # yellow-brown
  },
  {
    "Falcon Bus Services",
    "falcon",
    "Fast & Safe Inter-City Travel",
    "+260 977 100 900",
    nil,
    "#1e3a8a"   # navy
  },
  {
    "Savannah Bus Services",
    "savannah",
    "Comfortable Cross-Country Journeys",
    "+260 966 500 600",
    nil,
    "#78350f"   # brown
  },
  {
    "Supreme Bus Services",
    "supreme",
    "Premium Long Distance Travel",
    "+260 211 230 100",
    nil,
    "#312e81"   # indigo
  }
]

IO.puts "\n== Seeding Bus Companies (Operators) =="
{ins_ops, skip_ops} =
  Enum.reduce(operators, {0, 0}, fn {name, slug, tagline, phone, email, color}, {ins, skip} ->
    attrs = %{
      name: name,
      slug: slug,
      tagline: tagline,
      contact_phone: phone,
      contact_email: email,
      color: color,
      active: true
    }
    changeset = Operator.changeset(%Operator{}, attrs)
    if Repo.get_by(Operator, slug: slug) do
      IO.puts "  ~ #{name} (already exists)"
      {ins, skip + 1}
    else
      changeset = Operator.changeset(%Operator{}, attrs)
      case Repo.insert(changeset) do
        {:ok, op}   ->
          IO.puts "  + #{op.name}"
          {ins + 1, skip}
        {:error, cs} ->
          IO.puts "  ERROR #{name}: #{inspect(cs.errors)}"
          {ins, skip + 1}
      end
    end
  end)

IO.puts "\n== Done =="
IO.puts "  Operators: #{ins_ops} inserted, #{skip_ops} already existed"
IO.puts "  Routes:    #{inserted_routes} inserted, #{skipped_routes} already existed"
IO.puts "\nAll bus companies and routes are now available in the system."
IO.puts "You can now create schedules for each company on their routes via /schedules/new"
