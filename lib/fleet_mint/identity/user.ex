defmodule FleetMint.Identity.User do
  use Ecto.Schema
  import Ecto.Changeset

  # "platform_admin" and "tenant_admin" are deliberately distinct strings,
  # not one "admin" role distinguished only by organisation_id — role
  # checks (RequireRolePlug, per-controller guards) must be able to tell
  # them apart without also having to remember to check organisation_id
  # every time. validate_role_organisation_pairing/1 below keeps the
  # invariant (platform_admin <-> no organisation, everything else <->
  # has one) enforced at the data layer so the two can't drift apart.
  @valid_roles ["platform_admin", "tenant_admin", "manager", "cashier", "operator"]
  @email_regex ~r/^[^\s]+@[^\s]+$/

  schema "users" do
    field :active,          :boolean, default: false
    field :username,        :string
    field :role,            :string
    field :email,           :string
    field :password_hash,   :string
    field :password,        :string, virtual: true
    field :full_name,       :string
    # Job title, e.g. "Director" or "Accountant" — cosmetic only, distinct
    # from :role. Never gate authorization on this field; role is the only
    # source of truth for what a user can access.
    field :title,           :string
    field :phone,           :string
    field :last_login,      :naive_datetime
    field :totp_secret,     :string
    field :totp_enabled,    :boolean, default: false
    field :failed_attempts,        :integer, default: 0
    field :locked_until,           :naive_datetime
    field :reset_token_hash,       :string
    field :reset_token_expires_at, :naive_datetime

    # nil = platform-level (Miway staff, sees every organisation). Set =
    # tenant staff, scoped to that organisation's own data only.
    belongs_to :organisation, FleetMint.Identity.Organisation

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :role, :full_name, :title, :phone, :active, :last_login, :organisation_id])
    |> validate_required([:username, :email, :role, :full_name, :active])
    |> validate_format(:email, @email_regex, message: "must have the @ sign and no spaces")
    |> validate_inclusion(:role, @valid_roles, message: "must be one of: #{Enum.join(@valid_roles, ", ")}")
    |> validate_role_organisation_pairing()
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> foreign_key_constraint(:organisation_id)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password, :role, :full_name, :title, :active, :organisation_id])
    |> validate_required([:username, :email, :password, :role, :full_name])
    |> validate_format(:email, @email_regex, message: "must have the @ sign and no spaces")
    |> validate_inclusion(:role, @valid_roles, message: "must be one of: #{Enum.join(@valid_roles, ", ")}")
    |> validate_role_organisation_pairing()
    |> validate_length(:password, min: 12, max: 72, message: "must be at least 12 characters")
    |> validate_format(:password, ~r/[A-Z]/, message: "must contain at least one uppercase letter")
    |> validate_format(:password, ~r/[a-z]/, message: "must contain at least one lowercase letter")
    |> validate_format(:password, ~r/[0-9]/, message: "must contain at least one number")
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> foreign_key_constraint(:organisation_id)
    |> put_password_hash()
  end

  # A platform administrator has no organisation (sees across every
  # tenant); every other role belongs to exactly one. Enforced here, not
  # just by convention, so authorization checks that key off the role
  # string can trust it without re-deriving from organisation_id.
  defp validate_role_organisation_pairing(changeset) do
    role = get_field(changeset, :role)
    organisation_id = get_field(changeset, :organisation_id)

    cond do
      role == "platform_admin" and not is_nil(organisation_id) ->
        add_error(changeset, :organisation_id, "must be blank for a platform administrator")

      role in ["tenant_admin", "manager", "cashier", "operator"] and is_nil(organisation_id) ->
        add_error(changeset, :organisation_id, "is required for this role")

      true ->
        changeset
    end
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
