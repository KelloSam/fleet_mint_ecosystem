defmodule FleetMintWeb.Plugs.TenantScopePlug do
  @moduledoc """
  Runs after `AuthPlug` and assigns `:operator_scope` from the current
  user — `:all` for platform-level staff (`operator_id` nil), or that
  user's `operator_id` for tenant staff. Controllers and contexts filter
  queries against this instead of trusting the client or skipping the
  filter by convention.
  """

  import Plug.Conn

  alias FleetMint.Identity.Authorization

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns.current_user

    scope = if Authorization.platform_level?(user), do: :all, else: user.operator_id

    assign(conn, :operator_scope, scope)
  end
end
