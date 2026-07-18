defmodule FleetMintWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use FleetMintWeb, :controller` and
  `use FleetMintWeb, :live_view`.
  """
  use FleetMintWeb, :html

  embed_templates "layouts/*"

  # Mirrors the role groupings the router pipelines enforce server-side
  # (:require_manager / :require_admin / :require_platform_admin in
  # router.ex) so the sidebar only advertises links a role can actually
  # open. The router remains the real authorization boundary — these only
  # keep the menu from lying about it. `role` may be nil (unauthenticated
  # pages share this layout), which each clause below handles by simply
  # not matching.
  def manager_or_above?(role), do: role in ["platform_admin", "tenant_admin", "manager"]
  def admin_tier?(role), do: role in ["platform_admin", "tenant_admin"]
  def platform_admin_only?(role), do: role == "platform_admin"
end
