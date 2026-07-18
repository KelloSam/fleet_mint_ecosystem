defmodule FleetMintWeb.UserController do
  use FleetMintWeb, :controller
  alias FleetMint.Identity.Users
  alias FleetMint.Identity.User
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    page = FleetMint.Pagination.parse_page(params)
    paged = Users.list_users_paginated(page, organisation_id: conn.assigns.organisation_scope)
    render(conn, :index, paged: paged)
  end

  def new(conn, _params) do
    changeset = Users.change_user_registration(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    user_params = sanitize_params(user_params, conn.assigns.current_user)

    case Users.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User #{user.full_name} created.")
        |> redirect(to: ~p"/users/#{user}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Users.get_user!(id)

    with_organisation_access(conn, user.organisation_id, fn conn ->
      render(conn, :show, user: user)
    end)
  end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)

    with_organisation_access(conn, user.organisation_id, fn conn ->
      changeset = Users.change_user(user)
      render(conn, :edit, user: user, changeset: changeset)
    end)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Users.get_user!(id)

    with_organisation_access(conn, user.organisation_id, fn conn ->
      user_params = sanitize_params(user_params, conn.assigns.current_user)

      case Users.update_user(user, user_params) do
        {:ok, updated} ->
          conn
          |> put_flash(:info, "#{updated.full_name} updated.")
          |> redirect(to: ~p"/users/#{updated}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit, user: user, changeset: changeset)
      end
    end)
  end

  def activate(conn, %{"id" => id}) do
    user = Users.get_user!(id)

    with_organisation_access(conn, user.organisation_id, fn conn ->
      {:ok, _} = Users.activate_user(user)
      conn |> put_flash(:info, "#{user.full_name} activated.") |> redirect(to: ~p"/users")
    end)
  end

  def deactivate(conn, %{"id" => id}) do
    user = Users.get_user!(id)

    with_organisation_access(conn, user.organisation_id, fn conn ->
      {:ok, _} = Users.deactivate_user(user)
      conn |> put_flash(:info, "#{user.full_name} deactivated.") |> redirect(to: ~p"/users")
    end)
  end

  # ── Tenant scoping ──────────────────────────────────────────────────────

  # A platform_admin's params are trusted as submitted (their existing,
  # already-broad power). A tenant_admin's are corrected server-side,
  # never trusted as submitted: organisation_id is always forced to their
  # own (can't create/reassign a user into another organisation, or to
  # platform-level by nulling it out), and "platform_admin" is downgraded
  # to "tenant_admin" (can't self-escalate or grant platform authority to
  # anyone else). The role dropdown already hides "Platform Administrator"
  # from a tenant_admin (see UserHTML.role_options/1) — this is the half
  # of the guard that still holds if that form is bypassed entirely.
  defp sanitize_params(params, %User{role: "platform_admin"}), do: params

  defp sanitize_params(params, %User{role: "tenant_admin"} = tenant_admin) do
    params
    |> Map.put("organisation_id", tenant_admin.organisation_id)
    |> then(fn p -> if p["role"] == "platform_admin", do: Map.put(p, "role", "tenant_admin"), else: p end)
  end

  defp with_organisation_access(conn, organisation_id, fun) do
    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That user belongs to a different organisation.")
      |> redirect(to: ~p"/users")
    end
  end
end
