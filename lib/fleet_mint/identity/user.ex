defmodule FleetMint.Identity.User do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_roles ["admin", "manager", "cashier", "operator"]
  @email_regex ~r/^[^\s]+@[^\s]+$/

  schema "users" do
    field :active,          :boolean, default: false
    field :username,        :string
    field :role,            :string
    field :email,           :string
    field :password_hash,   :string
    field :password,        :string, virtual: true
    field :full_name,       :string
    field :phone,           :string
    field :last_login,      :naive_datetime
    field :totp_secret,     :string
    field :totp_enabled,    :boolean, default: false
    field :failed_attempts,        :integer, default: 0
    field :locked_until,           :naive_datetime
    field :reset_token_hash,       :string
    field :reset_token_expires_at, :naive_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :role, :full_name, :phone, :active, :last_login])
    |> validate_required([:username, :email, :role, :full_name, :active])
    |> validate_format(:email, @email_regex, message: "must have the @ sign and no spaces")
    |> validate_inclusion(:role, @valid_roles, message: "must be one of: #{Enum.join(@valid_roles, ", ")}")
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password, :role, :full_name, :active])
    |> validate_required([:username, :email, :password, :role, :full_name])
    |> validate_format(:email, @email_regex, message: "must have the @ sign and no spaces")
    |> validate_inclusion(:role, @valid_roles, message: "must be one of: #{Enum.join(@valid_roles, ", ")}")
    |> validate_length(:password, min: 12, max: 72, message: "must be at least 12 characters")
    |> validate_format(:password, ~r/[A-Z]/, message: "must contain at least one uppercase letter")
    |> validate_format(:password, ~r/[a-z]/, message: "must contain at least one lowercase letter")
    |> validate_format(:password, ~r/[0-9]/, message: "must contain at least one number")
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> put_password_hash()
  end

  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72, message: "must be at least 12 characters")
    |> validate_format(:password, ~r/[A-Z]/, message: "must contain at least one uppercase letter")
    |> validate_format(:password, ~r/[a-z]/, message: "must contain at least one lowercase letter")
    |> validate_format(:password, ~r/[0-9]/, message: "must contain at least one number")
    |> put_password_hash()
  end

  def security_changeset(user, attrs) do
    cast(user, attrs, [:failed_attempts, :locked_until])
  end

  def totp_changeset(user, attrs) do
    cast(user, attrs, [:totp_secret, :totp_enabled])
  end

  def reset_token_changeset(user, attrs) do
    cast(user, attrs, [:reset_token_hash, :reset_token_expires_at])
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
