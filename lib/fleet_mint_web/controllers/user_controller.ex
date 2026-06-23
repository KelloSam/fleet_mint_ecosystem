defmodule FleetMintWeb.UserController do
  use FleetMintWeb, :controller
  alias FleetMint.Accounts
  alias FleetMint.Accounts.User

  def index(conn, params) do
    page = FleetMint.Pagination.parse_page(params)
    paged = Accounts.list_users_paginated(page)
    render(conn, :index, paged: paged)
  end

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User #{user.full_name} created.")
        |> redirect(to: ~p"/users/#{user}")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, :edit, user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)
    case Accounts.update_user(user, user_params) do
      {:ok, updated} ->
        conn
        |> put_flash(:info, "#{updated.full_name} updated.")
        |> redirect(to: ~p"/users/#{updated}")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, user: user, changeset: changeset)
    end
  end

  def activate(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.activate_user(user)
    conn |> put_flash(:info, "#{user.full_name} activated.") |> redirect(to: ~p"/users")
  end

  def deactivate(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.deactivate_user(user)
    conn |> put_flash(:info, "#{user.full_name} deactivated.") |> redirect(to: ~p"/users")
  end
end
