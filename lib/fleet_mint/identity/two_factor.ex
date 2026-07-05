defmodule FleetMint.Identity.TwoFactor do
  @moduledoc """
  TOTP-based two-factor authentication: secret generation, verification,
  and enable/disable on a user's account.
  """

  alias FleetMint.Repo
  alias FleetMint.Identity.User

  def generate_totp_secret, do: NimbleTOTP.secret()

  def totp_uri(%User{email: email}, secret) do
    NimbleTOTP.otpauth_uri("FleetMint:#{email}", secret, issuer: "FleetMint")
  end

  def valid_totp?(%User{totp_secret: encoded}, code) when is_binary(encoded) do
    secret = Base.decode64!(encoded)
    NimbleTOTP.valid?(secret, code)
  end

  def valid_totp?(_, _), do: false

  def valid_totp_for_secret?(secret, code) when is_binary(secret) do
    NimbleTOTP.valid?(secret, code)
  end

  def enable_totp(%User{} = user, secret) when is_binary(secret) do
    user
    |> User.totp_changeset(%{totp_secret: Base.encode64(secret), totp_enabled: true})
    |> Repo.update()
  end

  def disable_totp(%User{} = user) do
    user
    |> User.totp_changeset(%{totp_secret: nil, totp_enabled: false})
    |> Repo.update()
  end
end
