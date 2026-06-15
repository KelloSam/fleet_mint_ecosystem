defmodule FleetMintWeb.AuthController do
  use FleetMintWeb, :controller

  alias FleetMint.Accounts
  alias FleetMint.Accounts.User
  alias FleetMint.Auth.Guardian

  def register(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, :register, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    user_params = Map.put_new(user_params, "active", true)
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        {:ok, _user, token} = Guardian.create_token(user)

        conn
        |> put_flash(:info, "Welcome, #{user.full_name}! Your account has been created.")
        |> put_session(:user_token, token)
        |> configure_session(renew: true)
        |> redirect(to: ~p"/dashboard")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :register, changeset: changeset)
    end
  end

  def login(conn, _params) do
    render(conn, :login, error_message: nil)
  end

  def authenticate(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Guardian.authenticate(email, password) do
      {:ok, user, token} ->
        Accounts.update_last_login(user)
        conn
        |> put_flash(:info, "Welcome back, #{user.full_name}!")
        |> put_session(:user_token, token)
        |> configure_session(renew: true)
        |> redirect(to: ~p"/dashboard")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render(:login, error_message: "Invalid email or password")
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/login")
  end
end

