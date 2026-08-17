# UI Refactor Checkpoint: UI-1 through UI-6

Same evidence standard as the `phaseN_*_checkpoint.md` docs, but this is a
separate track from those — the Constitution Phases cover tenancy/backend
hardening; this covers the dashboard/navigation/pagination/LiveView UI
refactor approved as its own controlled stage (UI-1 through UI-6). Written
because the acceptance review below made explicit that findings like this
shouldn't survive only in conversation history.

**Status: browser acceptance review complete (2026-08-17) — one real
defect found, not yet fixed. See §7.** One genuine defect (§7.1) was found
during the review; whether the UI phase can be treated as formally closed
depends on whether that defect gets fixed or is knowingly deferred — that
call is recorded in §7, not decided by this document.

## 1. What each stage shipped

| Stage | Commit | Summary |
|---|---|---|
| UI-1 | `57ce62a` | Sidebar scroll-containment bug (whole page scrolled instead of just `<main>`); unified 26 duplicated nav-link blocks into one `<.nav_link>` component with hover/focus-visible/active states |
| UI-2 | `1290f88` | Smaller hero (email removed); compact Staff On Duty widget replacing the full-width strip; Quick Actions trimmed (Print PDF moved under Reports); fixed a real tenant-scope gap — `Users.list_on_duty_staff/0` had no organisation filter at all |
| UI-3 | `665141a`, `5e70892` | Server-side pagination (25/page) for Routes, Audit Log, Cashing Reports, Expenditures, Fuel Logs, Minibus Trips, Operation Logs, via a shared `<.pagination>` component |
| UI-4 | `73d80cf` | Global Routes page shows a real fare *range* (`Routes.fare_ranges_for_routes/1`, min–max across operators' actual `Schedule.fare`) instead of one static number; Bus Company pages list each operator's real scheduled trips; built out the Schedules index page (controller was already complete, template was a placeholder) |
| UI-5 | `d98fb25` | First LiveView usage in the app: `FleetMintWeb.Live.AuthHooks` (on_mount auth/tenant-scope, mirroring `AuthPlug`/`TenantScopePlug` for the socket reconnect path); global topbar loading feedback extended to plain `<a href>`/form navigation (previously only fired for `<.link navigate>`/`phx-submit`); Staff On Duty and Routes converted to LiveView with live search/filter/pagination |
| UI-6 | `e60bb81` | Tenant-isolation regression tests added for Cashing Reports, Expenditures, Schedules (see §4 rule below); fixed a real bug — `<main>` had no `overflow-x`, so wide tables on narrow viewports weren't just visually cramped, columns were unreachable with no scrollbar; dashboard grids made to stack on narrow screens |

## 2. A bug the test suite did not catch

Mid-UI-5, both new LiveViews were built using `{expr}` for text-node HEEx
interpolation — the LiveView 1.0+ idiom. This app is pinned to
`phoenix_live_view 0.20.17`, where that syntax is silently treated as
literal text in text-node position (attribute-position `{expr}` is
unaffected and always worked). Both pages rendered with the literal source
text on screen (`{route.name}` printed verbatim, etc.), and **the full test
suite passed throughout — 0 failures** — because no test asserted on actual
rendered values for the new pages. Caught by manually curling the live
pages rather than trusting green tests; fixed by rewriting both to
`<%= expr %>`; two LiveView test files were added that assert on real
rendered content specifically so this class of bug fails loudly, not
silently, next time.

This is the direct precedent for the review discipline in this document and
for the rule in §4.

## 3. Verification (reproducible)

```bash
mix format --check-formatted   # clean except priv/repo/seeds.exs, which is
                                # someone else's uncommitted in-progress work
                                # on this branch, not touched by this stage
mix compile                    # clean (same pre-existing `prompt` attribute
                                # warnings noted in phase5's checkpoint, not
                                # new, not gating)
mix test
```

Actual result: **269 tests, 0 failures**, up from 261 at the start of this
UI stage (5 new LiveView tests in UI-5, 3 new tenant-scoping tests in UI-6).

## 4. New standing rule: financial/tenant-scoped listings need an explicit cross-tenant test

Going forward: **any tenant-scoped financial listing or aggregate must have
an explicit regression test proving Organisation A cannot observe
Organisation B's rows** — not merely that the query contains an
`organisation_id` filter. "The code looks right" is not the bar; a red test
without the fix is.

This was prompted by finding, during UI-6's audit, that Cashing Reports and
Expenditures (both paginated in UI-3) had zero such tests despite being
financial data, and Schedules (built out in UI-4) had none for its index at
all — in all three cases the scoping logic itself was already correct, the
test was what was missing. Fixed in `e60bb81`
(`cashing_report_controller_test.exs`, `expenditure_controller_test.exs`,
`schedule_controller_test.exs`), following the pattern already established
for fuel logs, minibus trips, and operation logs in Phase 5.

## 5. Decisions and deferred items

Recorded here rather than left to survive only in conversation history.

### 5.1 ChromicPDF startup timeout — OPEN, technical defect, not investigated

First observed at the very start of this session, unrelated to the UI
refactor: on `mix phx.server` startup, `ChromicPDF.Browser.SessionPool`
worker init fails with `ChromicPDF.Browser.ExecutionError: Timeout in
Channel.run_protocol/3!`, even though `/usr/bin/google-chrome` runs fine
headless when invoked directly (`google-chrome --headless --disable-gpu
--no-sandbox --dump-dom about:blank` succeeds). Likely a session-pool
startup race rather than a missing dependency, but this was never
investigated further — PDF/report-export features should be verified
working before being relied on. **Not fixed. Needs its own investigation
session.**

### 5.2 Responsive/mobile navigation — OPEN; design after stakeholder/device-use evidence

The sidebar is a fixed 256px column with no collapse/hamburger behavior.
Accepted as a known limitation for this UI stage, not a defect to silently
patch with a hamburger menu invented now. FleetMint's eventual users
(ticket sellers, managers, drivers, conductors, and other field/operational
staff) may need tablet/phone access for some workflows — which ones is a
product question, not an engineering one. Design real responsive
navigation after stakeholder/device-use evidence (interviews, field usage
data), not before.

### 5.3 Remaining listings still classic controllers, not LiveView — incremental modernization, not urgent

Schedules, Audit Log, Cashing Reports, Expenditures, Fuel Logs, Minibus
Trips, Operation Logs stay as classic controllers. UI-5 established the
on_mount/handle_params LiveView pattern (and both new LiveViews' auth/scope
plumbing is shared, not duplicated); converting the rest is a known,
low-risk mechanical follow-up whenever the UX value justifies prioritizing
it over other work. Not scheduled.

### 5.4 `/tickets` still a "Coming Soon" placeholder — product capability gap

`TicketController` (`index`, `show`, `validate`) is fully implemented; only
`ticket_html/index.html.heex` is still the scaffold "Coming Soon" page —
found while building out Schedules in UI-4 (which had the identical
symptom and was fixed there), left alone because QR ticket
listing/validation UI is a product-roadmap decision, not a UI-polish task.

## 6. What is explicitly not built / not checked here

- Mobile app (`mobile/` in this repo) not touched or re-checked; same
  caveat phase5's checkpoint already carries.

## 7. Browser acceptance review (2026-08-17)

Done via claude-in-chrome against the running dev server, logged in as
three real accounts in turn: `admin@kalemba.example` (tenant_admin, org
Kalemba), `admin@chibolya.example` (tenant_admin, org Chibolya), and
`platform@miway.example` (platform_admin). Not a curl/HTTP check — actual
clicks, actual rendered pixels, actual live interactions.

### 7.1 Defect: Operator page's "Scheduled Trips" can silently show nothing despite a real, active schedule existing — FIXED 2026-08-17

The UI-4 "Scheduled Trips" section on the Bus Company show page
(`operator_html/show.html.heex`) is nested inside the loop over
`@operator.routes` — which comes from the `operator_routes` join table, a
*separate* signal from "does this operator have a real `Schedule` on this
route." These two can disagree, and when they do, the newer one wins
silently: **Kalemba Coachlines has a real, active schedule** (`SCH-04A033`,
Lusaka → Livingstone, ZMW 270.00, 64 seats — confirmed present and correct
on `/schedules`) **but zero rows in `operator_routes`**, so its own Bus
Company page reads "No routes assigned yet" — the real commercial data is
invisible on the one page built to show it.

Confirmed this is specifically a data-consistency gap, not a broken
feature: Baobab Coachways (operator 11), whose `operator_routes` *is*
populated, renders the identical feature correctly — expanding "Lusaka →
Chipata" shows "SCHEDULED TRIPS: 11:30, BAO 2004, 65 seats available, ZMW
387.50, Active" exactly as designed.

**Fixed via option (a).** `Routes.get_operator_with_routes!/1`
(`lib/fleet_mint/transport/routes.ex`) now builds `operator.routes` from
the union of the `operator_routes` join and any route with a real
`Schedule` for that operator, rather than the join alone — a route that
has a schedule but no `operator_routes` row (or vice versa) still shows.
`operator_routes` was left as-is, not backfilled or enforced (option (b)
was not taken) — the write path is untouched, so the same drift can
recur, it just no longer hides data when it does. Two controller tests
added in `operator_controller_test.exs` covering both directions: a
schedule with no join row (the Kalemba case) and a join row with no
schedule yet (the pre-existing empty-state path). Full suite green
(269 tests, plus these 2, minus one pre-existing unrelated flaky test —
a random fixture-name collision in the tenant-listing test, reproducibly
passes in isolation).

### 7.2 UX Adjustments

- **FIXED 2026-08-17** (`1b7c063`): Role badge on the dashboard hero and
  elsewhere rendered the raw role enum through CSS `capitalize`, so
  `tenant_admin` displayed as "Tenant_admin" (visible underscore) instead
  of "Tenant Admin", visible on every login, every account.
  `CoreComponents.role_label/1` now title-cases each word; applied at every
  render site that used the `capitalize` class (dashboard hero, sidebar
  footer, user show page, staff-on-duty list, booking driver picker).
  Re-verified live, logged in as `admin@kalemba.example`: sidebar and hero
  both now read "Tenant Admin".
- **FIXED 2026-08-17** (`2269926`): The hero card had noticeably more empty
  vertical space than its stat-column neighbor for tenant_admin/manager
  accounts, because the card stretches to the grid row's full height (its
  stat-column neighbor's height) while its own content is naturally
  shorter. Centered the header/detail block vertically instead
  (`flex flex-col justify-center`). Re-verified live — no more dead space
  under the hero content.
- **FIXED 2026-08-17** (`96dbbc7`): The "Welcome back, {name}!" success
  flash toast did not auto-dismiss or respond to its close button on plain
  controller-rendered pages (only LiveView pages had a working
  `phx-click="lv:clear-flash"`, and even there nothing auto-dismissed).
  Added a plain-JS dismiss in `app.js` (`initFlashDismiss`, keyed off a new
  `data-flash` attribute) that hides the toast on click or after 6s,
  regardless of whether a LiveView socket is mounted; the existing
  `phx-click` is untouched so LiveView pages still clear flash state
  server-side too. Re-verified live: toast disappeared after ~6-9s
  unprompted, and a fresh toast dismissed instantly on click.
- Chibolya (tenant_admin `admin@chibolya.example`) has no Bus Company
  record at all ("No companies yet") and consequently no cashing
  reports/expenditures/buses either. Not treated as a defect — may be
  intentional (an org mid-onboarding) — but worth confirming with whoever
  owns seed data whether that's deliberate.

### 7.3 Confirmed working, live (not just via tests or curl)

- Hero: smaller, no email, ON DUTY badge, Staff ID/Phone/On Duty Since —
  as designed.
- Quick Actions: exactly 3 tiles (New Booking, Cashing Report,
  Expenditure) + a "PDF & report exports →" link; no Print PDF tile.
- Staff On Duty compact widget → LiveView roster page → live search
  (typed "zzz", got "No staff match 'zzz'." with no page reload).
- Sidebar: stays fixed while `<main>` scrolls (scrolled 8 ticks down a
  16-row table, sidebar didn't move); hover states fire; active-link
  highlighting persists correctly on the RoutesLive page specifically
  (confirms the UI-5 `current_path` fix holds under real navigation);
  consistent card styling across every item, including Maintenance.
- Routes: status-filter pills patch live (URL changes to
  `?status=active`, content updates, no full reload) — confirmed for both
  Active and Inactive.
- Fare ranges: global Routes page shows the aggregate range (e.g. "ZMW
  263.50 – 387.50"); a well-linked operator's page shows the real
  per-schedule fare instead. Both tenant accounts saw identical Routes
  data, confirming the global-catalogue design is working as intended, not
  leaking.
- Tenant isolation: Staff On Duty count differs correctly per tenant (1 vs
  1, different people); attempting `/operators/1` (Kalemba) as the
  Chibolya admin was blocked with a real, visible error — "That operator
  belongs to a different organisation."
- Role visibility: Audit Log absent from the sidebar for both tenant_admin
  accounts, present for platform_admin.
- LiveView loading feedback: topbar progress bar observed firing during
  full-page navigation between pages.

### 7.4 Not verified this session — tooling limitation, not a pass/fail result

- **Narrow-viewport rendering** (wide-table horizontal scroll, dashboard
  grid stacking): tried again 2026-08-17 — `resize_window` reports success
  (390×844) but the actual screenshot viewport still stayed fixed at the
  original size, same failure as the first attempt. Confirmed reproducible,
  not a one-off. The `overflow-x-auto` wrapper on the shared `table`
  component (`ebc15ab`) and the dashboard grid's `grid-cols-1 lg:grid-cols-3`
  (stacks to 1 column below Tailwind's `lg` breakpoint) are both correct by
  inspection, just still not visually re-verified at an actual narrow
  width. Needs a different tool/environment (real device emulation, not
  this extension's `resize_window`) to close out — not an app-side fix.
- **Routes pagination Prev/Next interaction**: only 16 routes exist in dev
  seed data against a 25/page size, so pagination controls never render to
  click. The live status-filter patch (§7.3) exercises the same
  `patch={true}` mechanism pagination uses, which is reassuring but not
  the same as clicking Next.
- **Direct two-tenant financial-listing leak test** (same cashing
  report/expenditure ID, two tenant sessions): not performable via UI —
  both demo tenant accounts have sparse/empty financial data (see §7.2).
  Cross-tenant *blocking* was confirmed live for Operators (§7.3). The
  UI-6 automated tests remain the primary evidence for Cashing
  Reports/Expenditures/Schedules isolation specifically.

---

**Commits covered by this checkpoint:** `57ce62a`, `1290f88`, `665141a`,
`5e70892`, `73d80cf`, `d98fb25`, `e60bb81`.
