defmodule FleetMintWeb.UserHTML do
  use FleetMintWeb, :html
  embed_templates "user_html/*"

  @doc """
  A tenant_admin never sees "Platform Administrator" as a choice — the
  UI-level half of the guard; UserController.sanitize_role/2 is the part
  that still holds if this form is bypassed entirely.
  """
  def role_options(%{role: "platform_admin"}) do
    [{"Platform Administrator", "platform_admin"}, {"Tenant Administrator", "tenant_admin"} | tenant_role_options()]
  end

  def role_options(_tenant_admin) do
    [{"Tenant Administrator", "tenant_admin"} | tenant_role_options()]
  end

  defp tenant_role_options, do: [{"Manager", "manager"}, {"Cashier", "cashier"}, {"Operator", "operator"}]
end
