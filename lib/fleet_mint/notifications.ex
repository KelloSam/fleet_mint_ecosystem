defmodule FleetMint.Notifications do
  import Swoosh.Email
  alias FleetMint.Mailer

  def password_reset_email(user, token) do
    reset_url = "http://localhost:4004/password-reset/#{token}"

    new()
    |> to({user.full_name, user.email})
    |> from({"FleetMint System", "no-reply@fleetmint.local"})
    |> subject("Password Reset Request")
    |> html_body("""
    <p>Hi #{user.full_name},</p>
    <p>Click the link below to reset your password. This link expires in 1 hour.</p>
    <p><a href="#{reset_url}">Reset Password</a></p>
    <p>If you did not request this, ignore this email.</p>
    """)
    |> text_body("Reset your password: #{reset_url}\n\nExpires in 1 hour.")
    |> Mailer.deliver()
  end
end
