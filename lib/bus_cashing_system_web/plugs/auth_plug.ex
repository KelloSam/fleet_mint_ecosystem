defmodule BusCashingSystemWeb.Plugs.AuthPlug do
  import Plug.Conn
  import Phoenix.Controller
  use BusCashingSystemWeb, :verified_routes

  alias BusCashingSystem.Auth.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_current_user(conn) do
      {:ok, user} ->
        # User is authenticated, add user to conn.assigns
        assign(conn, :current_user, user)
      
      _error ->
        # User is not authenticated, redirect to login
        conn
        |> put_flash(:error, "You must be logged in to access this page")
        |> redirect(to: ~p"/login")
        |> halt()
    end
  end

  @doc """
  Get the current authenticated user from the session
  """
  def get_current_user(conn) do
    with token when not is_nil(token) <- get_session(conn, :user_token),
         {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, user} <- Guardian.resource_from_claims(claims) do
      {:ok, user}
    else
      _error -> {:error, :unauthorized}
    end
  end

  @doc """
  Helper to determine if a user is logged in (for use in templates)
  """
  def logged_in?(conn) do
    case get_current_user(conn) do
      {:ok, _user} -> true
      _ -> false
    end
  end
end

