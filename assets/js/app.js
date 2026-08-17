// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// The events above fire automatically for `<.link navigate={...}>` clicks
// and for `phx-submit` forms, live or dead. Most of this app is still
// classic controller-rendered pages though, so plain `<a href>` clicks
// (filter pills, "New X" buttons, method="delete" links) and plain
// `<form>` submits (every create/edit page) never dispatched those events
// and showed no feedback at all while the server round-trip was in
// flight. Show the same topbar for those too, so every click gets an
// immediate visual response regardless of which navigation mechanism the
// target page happens to use.
document.addEventListener("click", e => {
  const link = e.target.closest("a[href]")
  if (!link || link.hasAttribute("data-phx-link")) return
  if (e.defaultPrevented || e.button !== 0) return
  if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return
  if (link.target && link.target !== "_self") return
  if (link.hasAttribute("download")) return
  if (link.origin !== window.location.origin) return
  if (/^(mailto|tel):/.test(link.protocol)) return

  topbar.show(300)
})

document.addEventListener("submit", e => {
  if (e.target instanceof HTMLFormElement && !e.target.hasAttribute("phx-submit")) {
    topbar.show(300)
  }
})

// The flash toast's phx-click (JS.push("lv:clear-flash") |> JS.hide(...))
// only fires reliably when a LiveView socket is actually mounted on the
// page. Most of this app is still classic controller-rendered pages
// (e.g. straight after login), where that click handler and the button
// inside it are inert and the toast just sits there forever. Handle
// dismiss (click or the close button) and a timed auto-dismiss here in
// plain JS instead, so both dead and live pages behave the same way.
function initFlashDismiss() {
  document.querySelectorAll("[data-flash]").forEach(el => {
    if (el.dataset.flashBound) return
    el.dataset.flashBound = "true"

    const dismiss = () => { el.style.display = "none" }

    el.addEventListener("click", dismiss)
    setTimeout(dismiss, 6000)
  })
}

document.addEventListener("DOMContentLoaded", initFlashDismiss)
window.addEventListener("phx:page-loading-stop", initFlashDismiss)

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

