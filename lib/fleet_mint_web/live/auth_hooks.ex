defmodule FleetMintWeb.Live.AuthHooks do
  @moduledoc """
  `on_mount` hook for `live_session`s, mirroring what `AuthPlug` and
  `TenantScopePlug` already do for controllers. Those plugs only run on
  the initial HTTP request that renders a LiveView's static shell — the
  websocket (re)connect never goes through the router pipeline, so a
  LiveView needs this to authenticate and scope itself on every mount,
  not just the first one.
  """

  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  alias FleetMint.Identity.Guardian
  alias FleetMint.Identity.Authorization

  def on_mount(:default, _params, session, socket) do
    with token when not is_nil(token) <- session["user_token"],
         {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, user} <- Guardian.resource_from_claims(claims) do
      scope = if Authorization.platform_level?(user), do: :all, else: user.organisation_id

      socket =
        socket
        |> assign(:current_user, user)
        |> assign(:organisation_scope, scope)
        |> attach_hook(:assign_current_path, :handle_params, fn _params, uri, socket ->
          {:cont, assign(socket, :current_path, URI.parse(uri).path)}
        end)

      {:cont, socket}
    else
      _ ->
        {:halt, redirect(socket, to: "/login")}
    end
  end
end
