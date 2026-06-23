defmodule FleetMintWeb.AuthController do
  use FleetMintWeb, :controller

  alias FleetMint.Accounts
  alias FleetMint.Accounts.User
  alias FleetMint.Auth.Guardian
  alias FleetMint.AuditLogs

  def register(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, :register, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    # Strip any role or active flags submitted by the user — all self-registered
    # accounts land as inactive "staff" and require admin approval before login.
    user_params =
      user_params
      |> Map.put("role", "staff")
      |> Map.put("active", false)

    case Accounts.create_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Account created. An administrator must activate it before you can log in.")
        |> redirect(to: ~p"/login")

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
        AuditLogs.log("login_success",
          actor_id: user.id,
          actor_email: user.email,
          ip_address: get_ip(conn)
        )

        conn = configure_session(conn, renew: true)

        if user.totp_enabled do
          conn
          |> put_session(:pending_2fa_user_id, user.id)
          |> redirect(to: ~p"/login/verify")
        else
          conn
          |> put_session(:user_token, token)
          |> put_flash(:info, "Welcome back, #{user.full_name}!")
          |> redirect(to: ~p"/dashboard")
        end

      {:error, {:account_locked, locked_until}} ->
        remaining = max(1, div(NaiveDateTime.diff(locked_until, NaiveDateTime.utc_now(), :second), 60))

        AuditLogs.log("login_blocked_lockout",
          actor_email: email,
          ip_address: get_ip(conn),
          metadata: %{attempted_email: email}
        )

        conn
        |> put_flash(:error, "Account locked after too many failed attempts. Try again in #{remaining} minute(s).")
        |> render(:login, error_message: "Account temporarily locked. Try again in #{remaining} minute(s).")

      {:error, :inactive_account} ->
        conn
        |> put_flash(:error, "Your account is inactive. Contact an administrator.")
        |> render(:login, error_message: "Account inactive.")

      {:error, _} ->
        AuditLogs.log("login_failure",
          actor_email: email,
          ip_address: get_ip(conn),
          metadata: %{attempted_email: email}
        )

        conn
        |> put_flash(:error, "Invalid email or password.")
        |> render(:login, error_message: "Invalid email or password.")
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/login")
  end

  defp get_ip(conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip
      [] -> to_string(:inet.ntoa(conn.remote_ip))
    end
  end
end
