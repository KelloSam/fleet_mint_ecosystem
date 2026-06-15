# ============================================================
# Seed operator-route associations + add Jordan Bus Services
# Run with:  mix run priv/repo/seeds_operator_routes.exs
# Safe to re-run — skips existing associations
# ============================================================
alias FleetMint.Repo
alias FleetMint.Fleet.{Operator, Route}
import Ecto.Query

# Helper: get operator by slug
op = fn slug ->
  Repo.get_by(Operator, slug: slug)
end

# Helper: get route by name (substring match at start)
rt = fn name ->
  Repo.one(from r in Route, where: like(r.name, ^"#{name}%"), limit: 1)
end

# Helper: link operator to route (safe, skips if already linked)
link = fn operator, route ->
  if operator && route do
    Repo.insert_all("operator_routes",
      [%{operator_id: operator.id, route_id: route.id}],
      on_conflict: :nothing)
  end
end

# ── Add Jordan Bus Services if not already there ──────────────────────────────
IO.puts "\n== Adding Jordan Bus Services =="
unless Repo.get_by(Operator, slug: "jordan") do
  %Operator{}
  |> Operator.changeset(%{
    name: "Jordan Bus Services",
    slug: "jordan",
    tagline: "Zambia to South Africa and Beyond",
    contact_phone: "+260 977 050 100",
    contact_email: nil,
    color: "#0f172a",
    active: true
  })
  |> Repo.insert!()
  IO.puts "  + Jordan Bus Services added"
else
  IO.puts "  ~ Jordan Bus Services already exists"
end

# ── Operator → Route Associations ────────────────────────────────────────────
IO.puts "\n== Seeding Operator Routes =="

associations = [
  # Mazhandu — all major corridors
  {"mazhandu", [
    "Lusaka → Livingstone",
    "Lusaka → Chipata",
    "Lusaka → Ndola",
    "Lusaka → Kitwe",
    "Lusaka → Kabwe",
    "Lusaka → Kasama",
    "Lusaka → Mongu",
    "Lusaka → Solwezi",
    "Lusaka → Harare",
    "Lusaka → Mpika",
    "Lusaka → Mansa",
    "Lusaka → Serenje",
    "Lusaka → Choma",
    "Lusaka → Petauke"
  ]},

  # CR Carriers — established routes
  {"cr-carriers", [
    "Lusaka → Livingstone",
    "Lusaka → Chipata",
    "Lusaka → Ndola",
    "Lusaka → Kitwe",
    "Lusaka → Kabwe",
    "Lusaka → Kasama",
    "Lusaka → Mansa",
    "Lusaka → Mpika",
    "Lusaka → Serenje",
    "Lusaka → Choma",
    "Lusaka → Mazabuka"
  ]},

  # Power Tools — Southern + Copperbelt
  {"power-tools", [
    "Lusaka → Livingstone",
    "Lusaka → Ndola",
    "Lusaka → Kitwe",
    "Lusaka → Chipata",
    "Lusaka → Chingola",
    "Lusaka → Choma",
    "Lusaka → Kabwe"
  ]},

  # Shalom — Eastern Province specialist
  {"shalom", [
    "Lusaka → Chipata",
    "Lusaka → Lundazi",
    "Lusaka → Petauke",
    "Lusaka → Nyimba",
    "Lusaka → Katete",
    "Lusaka → Mfuwe"
  ]},

  # Juldan Motors — Southern + Copperbelt
  {"juldan-motors", [
    "Lusaka → Livingstone",
    "Lusaka → Ndola",
    "Lusaka → Kitwe",
    "Lusaka → Kabwe",
    "Lusaka → Choma",
    "Lusaka → Monze",
    "Lusaka → Mazabuka"
  ]},

  # Euro Africa — International focus
  {"euro-africa", [
    "Lusaka → Livingstone",
    "Lusaka → Ndola",
    "Lusaka → Kitwe",
    "Lusaka → Harare (Zimbabwe)",
    "Lusaka → Johannesburg (South Africa)",
    "Lusaka → Lilongwe (Malawi)",
    "Lusaka → Dar es Salaam (Tanzania)"
  ]},

  # Germins — Eastern Province
  {"germins", [
    "Lusaka → Chipata",
    "Lusaka → Mfuwe",
    "Lusaka → Petauke",
    "Lusaka → Katete",
    "Lusaka → Lundazi"
  ]},

  # Kobs — Great East Road
  {"kobs", [
    "Lusaka → Chipata",
    "Lusaka → Petauke",
    "Lusaka → Katete",
    "Lusaka → Nyimba",
    "Lusaka → Lundazi"
  ]},

  # Taqwa — Northern + Copperbelt
  {"taqwa", [
    "Lusaka → Ndola",
    "Lusaka → Kitwe",
    "Lusaka → Solwezi",
    "Lusaka → Kabwe",
    "Lusaka → Chingola",
    "Lusaka → Kapiri Mposhi",
    "Lusaka → Kasama"
  ]},

  # Likili — Luapula Province
  {"likili", [
    "Lusaka → Mansa",
    "Lusaka → Nchelenge",
    "Lusaka → Kawambwa",
    "Lusaka → Samfya",
    "Lusaka → Serenje",
    "Lusaka → Kasama"
  ]},

  # Kansanshi — North-Western Province
  {"kansanshi", [
    "Lusaka → Solwezi",
    "Lusaka → Chingola",
    "Lusaka → Kitwe",
    "Lusaka → Kasempa",
    "Lusaka → Mwinilunga",
    "Lusaka → Ndola"
  ]},

  # Fedha — Copperbelt
  {"fedha", [
    "Lusaka → Ndola",
    "Lusaka → Kitwe",
    "Lusaka → Chingola",
    "Lusaka → Luanshya",
    "Lusaka → Mufulira",
    "Lusaka → Kabwe"
  ]},

  # Timmy — Eastern Province affordable
  {"timmy", [
    "Lusaka → Chipata",
    "Lusaka → Petauke",
    "Lusaka → Katete",
    "Lusaka → Nyimba"
  ]},

  # Johansen — Southern Corridor
  {"johansen", [
    "Lusaka → Livingstone",
    "Lusaka → Choma",
    "Lusaka → Mazabuka",
    "Lusaka → Monze",
    "Lusaka → Kalomo",
    "Lusaka → Kafue"
  ]},

  # Cross Country — Nationwide
  {"cross-country", [
    "Lusaka → Livingstone",
    "Lusaka → Choma",
    "Lusaka → Kafue",
    "Lusaka → Ndola",
    "Lusaka → Kitwe",
    "Lusaka → Kabwe",
    "Lusaka → Chipata"
  ]},

  # Nkashama — Northern Province
  {"nkashama", [
    "Lusaka → Kasama",
    "Lusaka → Mbala",
    "Lusaka → Mpika",
    "Lusaka → Nakonde",
    "Lusaka → Serenje",
    "Lusaka → Kapiri Mposhi"
  ]},

  # Shadreck — Eastern Province affordable
  {"shadreck", [
    "Lusaka → Chipata",
    "Lusaka → Petauke",
    "Lusaka → Lundazi",
    "Lusaka → Katete"
  ]},

  # Taonga Tours — Tourism routes
  {"taonga-tours", [
    "Lusaka → Livingstone",
    "Lusaka → Mongu",
    "Lusaka → Ndola",
    "Lusaka → Chipata",
    "Lusaka → Mfuwe"
  ]},

  # Western Province Bus
  {"western-province-bus", [
    "Lusaka → Mongu",
    "Lusaka → Kaoma",
    "Lusaka → Mumbwa",
    "Lusaka → Senanga",
    "Lusaka → Sesheke"
  ]},

  # Falcon — Fast inter-city
  {"falcon", [
    "Lusaka → Livingstone",
    "Lusaka → Ndola",
    "Lusaka → Kitwe",
    "Lusaka → Chipata",
    "Lusaka → Kabwe",
    "Lusaka → Choma"
  ]},

  # Savannah — Comfort cross-country
  {"savannah", [
    "Lusaka → Livingstone",
    "Lusaka → Ndola",
    "Lusaka → Chipata",
    "Lusaka → Kasama",
    "Lusaka → Mongu",
    "Lusaka → Solwezi"
  ]},

  # Supreme — Premium travel
  {"supreme", [
    "Lusaka → Livingstone",
    "Lusaka → Ndola",
    "Lusaka → Chipata",
    "Lusaka → Harare (Zimbabwe)",
    "Lusaka → Johannesburg (South Africa)",
    "Lusaka → Kitwe"
  ]},

  # Jordan Bus Services — South Africa + local
  {"jordan", [
    "Lusaka → Johannesburg (South Africa)",
    "Lusaka → Harare (Zimbabwe)",
    "Lusaka → Kasama",
    "Lusaka → Solwezi",
    "Lusaka → Livingstone",
    "Lusaka → Chipata",
    "Lusaka → Ndola",
    "Lusaka → Kitwe",
    "Lusaka → Mbala",
    "Lusaka → Nakonde",
    "Lusaka → Dar es Salaam (Tanzania)"
  ]}
]

total_linked = 0
total_skipped = 0

{total_linked, total_skipped} =
  Enum.reduce(associations, {0, 0}, fn {slug, route_names}, {linked, skipped} ->
    operator = op.(slug)
    unless operator do
      IO.puts "  ! Operator not found: #{slug}"
      {linked, skipped}
    else
      {l, s} = Enum.reduce(route_names, {0, 0}, fn route_name, {rl, rs} ->
        route = rt.(route_name)
        if route do
          {count, _} = link.(operator, route)
          if count > 0, do: {rl + 1, rs}, else: {rl, rs + 1}
        else
          IO.puts "    ! Route not found: #{route_name} (for #{operator.name})"
          {rl, rs + 1}
        end
      end)
      IO.puts "  #{operator.name}: #{l} linked, #{s} already existed"
      {linked + l, skipped + s}
    end
  end)

IO.puts "\n== Done =="
IO.puts "  New links created: #{total_linked}"
IO.puts "  Already existed:   #{total_skipped}"
IO.puts "\nVisit /operators to see all companies with their routes."
