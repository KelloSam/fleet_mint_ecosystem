# FleetMint

Transport fleet management platform (buses, minibuses, freight, ticketing,
finance) for Zambian bus operators and logistics companies. See
`docs/PLATFORM_ARCHITECTURE_ROADMAP.md` for current architecture status and
`docs/phaseN_*checkpoint.md` / `docs/stage_*_checkpoint.md` for what's been
verified working at each stage.

## Development setup

  * Requires PostgreSQL reachable at the host/port set in `config/dev.exs`
    (defaults to port 5433, user `think`).
  * Run `mix setup` — installs dependencies, creates and migrates the dev
    database, seeds it, and builds assets.
  * Start the server with `mix phx.server` (or `iex -S mix phx.server`) and
    visit [`localhost:4004`](http://localhost:4004).

`mix setup` runs `priv/repo/seeds.exs`, which creates two fictional
development tenants — a complete reference tenant ("Kalemba Coachlines")
touching every implemented domain, and a second, deliberately minimal
freight-only tenant ("Chibolya Logistics") with no passenger-transport
Operator profile at all, to demonstrate tenant isolation and the
Organisation-not-Operator tenant root. The script prints login credentials
for every seeded user when it finishes. **This is fictional dev/demo data
only** — the real FleetMint pilot organisation and its data are a separate,
controlled process (see `docs/pilot/PILOT_DEFINITION.md`) and must never be
added to this file.

To rebuild the dev database from scratch (drops all data):

```
mix ecto.reset
```

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
