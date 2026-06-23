defmodule FleetMintWeb.PasswordResetController do
  use FleetMintWeb, :controller
  alias FleetMint.Accounts
  alias FleetMint.Notifications

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"email" => email}) do
    case Accounts.request_password_reset(email) do
      {:ok, user, token} ->
        Notifications.password_reset_email(user, token)
        conn
        |> put_flash(:info, "If that email exists, a reset link has been sent.")
        |> redirect(to: ~p"/login")
      {:error, _} ->
        conn
        |> put_flash(:info, "If that email exists, a reset link has been sent.")
        |> redirect(to: ~p"/login")
    end
  end

  def edit(conn, %{"token" => token}) do
    render(conn, :edit, token: token, error: nil)
  end

  def update(conn, %{"token" => token, "password" => password}) do
    case Accounts.reset_password_by_token(token, password) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password updated. Please sign in.")
        |> redirect(to: ~p"/login")
      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "Reset link is invalid.")
        |> redirect(to: ~p"/password-reset")
      {:error, :expired_token} ->
        conn
        |> put_flash(:error, "Reset link has expired. Please request a new one.")
        |> redirect(to: ~p"/password-reset")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, token: token, error: changeset_error(changeset))
    end
  end

  defp changeset_error(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    |> Enum.map(fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
    |> Enum.join("; ")
  end
end
