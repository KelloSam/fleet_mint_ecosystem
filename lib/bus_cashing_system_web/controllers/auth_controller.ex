defmodule BusCashingSystemWeb.AuthController do
  use BusCashingSystemWeb, :controller

  alias BusCashingSystem.Accounts
  alias BusCashingSystem.Accounts.User
  alias BusCashingSystem.Auth.Guardian

  def register(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, :register, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        {:ok, _user, token} = Guardian.create_token(user)

        conn
        |> put_flash(:info, "User created successfully.")
        |> put_session(:user_token, token)
        |> configure_session(renew: true)
        |> redirect(to: ~p"/")

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
        conn
        |> put_flash(:info, "Welcome back, #{user.name}!")
        |> put_session(:user_token, token)
        |> configure_session(renew: true)
        |> redirect(to: ~p"/")

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

