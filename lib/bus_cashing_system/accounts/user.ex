defmodule BusCashingSystem.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_roles ["admin", "manager", "cashier", "operator"]
  @email_regex ~r/^[^\s]+@[^\s]+$/
  @min_password_length 8

  schema "users" do
    field :active, :boolean, default: false
    field :username, :string
    field :role, :string
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :full_name, :string
    field :last_login, :naive_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Standard changeset for updating user details.
  Does not handle password changes which should use a separate changeset.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :role, :full_name, :active, :last_login])
    |> validate_required([:username, :email, :role, :full_name, :active])
    |> validate_format(:email, @email_regex, message: "must have the @ sign and no spaces")
    |> validate_inclusion(:role, @valid_roles, message: "must be one of: #{Enum.join(@valid_roles, ", ")}")
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  @doc """
  A changeset for registering new users.
  It requires a password and handles password hashing using Bcrypt.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password, :role, :full_name, :active])
    |> validate_required([:username, :email, :password, :role, :full_name])
    |> validate_format(:email, @email_regex, message: "must have the @ sign and no spaces")
    |> validate_inclusion(:role, @valid_roles, message: "must be one of: #{Enum.join(@valid_roles, ", ")}")
    |> validate_length(:password, min: @min_password_length, 
        message: "should be at least #{@min_password_length} character(s)")
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> put_password_hash()
  end

  @doc """
  A changeset for changing the user password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: @min_password_length, 
        message: "should be at least #{@min_password_length} character(s)")
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Bcrypt.hash_pwd_salt(password))
  end
  
  defp put_password_hash(changeset), do: changeset
end
