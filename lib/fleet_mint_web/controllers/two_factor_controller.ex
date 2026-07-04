defmodule FleetMintWeb.TwoFactorController do
  use FleetMintWeb, :controller

  alias FleetMint.Identity
  alias FleetMint.Identity.Guardian
  alias FleetMint.Administration

  # ── 2FA verify step (after password, before full session) ──────────────────

  def verify(conn, _params) do
    if get_session(conn, :pending_2fa_user_id) do
      render(conn, :verify)
    else
      redirect(conn, to: ~p"/login")
    end
  end

  def confirm(conn, %{"totp" => %{"code" => code}}) do
    user_id = get_session(conn, :pending_2fa_user_id)

    with true <- not is_nil(user_id),
         user = Identity.get_user!(user_id),
         true <- Identity.valid_totp?(user, code) do
      {:ok, _user, token} = Guardian.create_token(user)

      Administration.log("2fa_success",
        actor_id: user.id,
        actor_email: user.email,
        ip_address: get_ip(conn)
      )

      conn
      |> delete_session(:pending_2fa_user_id)
      |> put_session(:user_token, token)
      |> configure_session(renew: true)
      |> put_flash(:info, "Welcome back, #{user.full_name}!")
      |> redirect(to: ~p"/dashboard")
    else
      _ ->
        Administration.log("2fa_failure", ip_address: get_ip(conn))

        conn
        |> put_flash(:error, "Invalid or expired code. Please try again.")
        |> render(:verify)
    end
  end

  # ── 2FA settings (admin/manager only) ──────────────────────────────────────

  def setup(conn, _params) do
    user = Identity.get_user!(conn.assigns.current_user.id)
    secret = Identity.generate_totp_secret()
    uri = Identity.totp_uri(user, secret)
    qr_svg = uri |> EQRCode.encode() |> EQRCode.svg(width: 220)
    manual_key = Base.encode32(secret, padding: false)

    conn
    |> put_session(:pending_totp_secret, Base.encode64(secret))
    |> render(:setup, user: user, qr_svg: qr_svg, manual_key: manual_key)
  end

  def enable(conn, %{"totp" => %{"code" => code}}) do
    user = Identity.get_user!(conn.assigns.current_user.id)
    encoded_secret = get_session(conn, :pending_totp_secret)

    with true <- is_binary(encoded_secret),
         secret = Base.decode64!(encoded_secret),
         true <- Identity.valid_totp_for_secret?(secret, code),
         {:ok, _} <- Identity.enable_totp(user, secret) do
      Administration.log("2fa_enabled",
        actor_id: user.id,
        actor_email: user.email,
        ip_address: get_ip(conn)
      )

      conn
      |> delete_session(:pending_totp_secret)
      |> put_flash(:info, "Two-factor authentication enabled.")
      |> redirect(to: ~p"/settings/2fa")
    else
      _ ->
        conn
        |> put_flash(:error, "Code did not match. Please scan the QR code again and try once more.")
        |> redirect(to: ~p"/settings/2fa")
    end
  end

  def disable(conn, _params) do
    user = Identity.get_user!(conn.assigns.current_user.id)
    Identity.disable_totp(user)

    Administration.log("2fa_disabled",
      actor_id: user.id,
      actor_email: user.email,
      ip_address: get_ip(conn)
    )

    conn
    |> put_flash(:info, "Two-factor authentication disabled.")
    |> redirect(to: ~p"/settings/2fa")
  end

  defp get_ip(conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip
      [] -> to_string(:inet.ntoa(conn.remote_ip))
    end
  end
end
