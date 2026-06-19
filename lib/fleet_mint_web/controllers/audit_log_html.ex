defmodule FleetMintWeb.AuditLogHTML do
  use FleetMintWeb, :html
  embed_templates "audit_log_html/*"

  def format_event(event) do
    event |> String.replace("_", " ") |> String.capitalize()
  end

  def event_color("login_failure"),        do: "text-red-700 bg-red-50"
  def event_color("login_blocked_lockout"), do: "text-orange-700 bg-orange-50"
  def event_color("login_success"),        do: "text-green-700 bg-green-50"
  def event_color("2fa_success"),          do: "text-green-700 bg-green-50"
  def event_color("2fa_failure"),          do: "text-red-700 bg-red-50"
  def event_color("2fa_enabled"),          do: "text-blue-700 bg-blue-50"
  def event_color("2fa_disabled"),         do: "text-yellow-700 bg-yellow-50"
  def event_color(_),                      do: "text-gray-600 bg-gray-100"
end
