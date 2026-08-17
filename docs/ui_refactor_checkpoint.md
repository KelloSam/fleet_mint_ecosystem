# UI Refactor Checkpoint: UI-1 through UI-6

Same evidence standard as the `phaseN_*_checkpoint.md` docs, but this is a
separate track from those — the Constitution Phases cover tenancy/backend
hardening; this covers the dashboard/navigation/pagination/LiveView UI
refactor approved as its own controlled stage (UI-1 through UI-6). Written
because the acceptance review below made explicit that findings like this
shouldn't survive only in conversation history.

**Status: UI phase NOT yet formally closed.** Automated tests are green
(§3), but the gate agreed for this phase is *automated tests green +
browser acceptance review passed + known defects recorded* — the browser
review is pending on the claude-in-chrome extension being connected in this
environment. This document will be updated with the review's findings
(Defect / UX Adjustment / Deferred Enhancement) once it runs, and the
status line above updated to reflect closure or not.

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

- No visual/interactive browser review of any of §1's work — see the
  status line at the top of this document.
- No second tenant-account walkthrough of the financial/schedule pages
  beyond the automated tests in §4 — planned as part of the same browser
  review.
- Mobile app (`mobile/` in this repo) not touched or re-checked; same
  caveat phase5's checkpoint already carries.

---

**Commits covered by this checkpoint:** `57ce62a`, `1290f88`, `665141a`,
`5e70892`, `73d80cf`, `d98fb25`, `e60bb81`.
