defmodule FleetMint.Accounts do
  @moduledoc """
  The Accounts context.
  
  This context handles operations related to user management, authentication,
  and authorization. It provides functions to create, read, update, and delete users,
  as well as specialized functions for authentication and security.
  """
  
  import Ecto.Query, warn: false
  alias FleetMint.Repo
  alias FleetMint.Accounts.User
  
  @doc """
  Returns the list of users.
  
  ## Examples
  
      iex> list_users()
      [%User{}, ...]
  
  """
  def list_users do
    Repo.all(User)
  end
  
  @doc """
  Gets a single user.
  
  Raises `Ecto.NoResultsError` if the User does not exist.
  
  ## Examples
  
      iex> get_user!(123)
      %User{}
      
      iex> get_user!(456)
      ** (Ecto.NoResultsError)
  
  """
  def get_user!(id), do: Repo.get!(User, id)
  
  @doc """
  Gets a single user.
  
  Returns nil if the User does not exist.
  
  ## Examples
  
      iex> get_user(123)
      %User{}
      
      iex> get_user(456)
      nil
  
  """
  def get_user(id), do: Repo.get(User, id)
  
  @doc """
  Gets a user by their email address.
  
  Returns nil if no user exists with the given email.
  
  ## Examples
  
      iex> get_user_by_email("user@example.com")
      %User{}
      
      iex> get_user_by_email("nonexistent@example.com")
      nil
  
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end
  
  @doc """
  Gets a user by their username.
  
  Returns nil if no user exists with the given username.
  
  ## Examples
  
      iex> get_user_by_username("johndoe")
      %User{}
      
      iex> get_user_by_username("nonexistent")
      nil
  
  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end
  
  @doc """
  Creates a user.
  
  ## Examples
  
      iex> create_user(%{field: value})
      {:ok, %User{}}
      
      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Updates a user.
  
  ## Examples
  
      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}
      
      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end
  
  @doc """
  Deletes a user.
  
  ## Examples
  
      iex> delete_user(user)
      {:ok, %User{}}
      
      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}
  
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end
  
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  
  ## Examples
  
      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}
  
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
  
  @doc """
  Returns a user registration changeset for creating new users.
  
  ## Examples
  
      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}
  
  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end
  
  @doc """
  Changes a user's password.
  
  ## Examples
  
      iex> update_user_password(user, "valid password")
      {:ok, %User{}}
      
      iex> update_user_password(user, "invalid")
      {:error, %Ecto.Changeset{}}
  
  """
  def update_user_password(%User{} = user, password) do
    user
    |> User.password_changeset(%{password: password})
    |> Repo.update()
  end
  
  @doc """
  Activates a user account.
  
  ## Examples
  
      iex> activate_user(user)
      {:ok, %User{}}
  
  """
  def activate_user(%User{} = user) do
    update_user(user, %{active: true})
  end
  
  @doc """
  Deactivates a user account.
  
  ## Examples
  
      iex> deactivate_user(user)
      {:ok, %User{}}
  
  """
  def deactivate_user(%User{} = user) do
    update_user(user, %{active: false})
  end
  
  @doc """
  Changes a user's role.
  
  ## Examples
  
      iex> change_user_role(user, "manager")
      {:ok, %User{}}
      
      iex> change_user_role(user, "invalid_role")
      {:error, %Ecto.Changeset{}}
  
  """
  def change_user_role(%User{} = user, role) when is_binary(role) do
    update_user(user, %{role: role})
  end
  
  @doc """
  Returns the list of users with a specific role.
  
  ## Examples
  
      iex> list_users_by_role("manager")
      [%User{}, ...]
  
  """
  def list_users_by_role(role) when is_binary(role) do
    query = from u in User,
            where: u.role == ^role,
            order_by: [asc: u.username]
    Repo.all(query)
  end

  def update_last_login(%User{} = user) do
    user
    |> Ecto.Changeset.change(last_login: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> Repo.update()
  end

  def list_on_duty_staff do
    today_start = NaiveDateTime.new!(Date.utc_today(), ~T[00:00:00])
    from(u in User,
      where: u.role in ["admin", "manager", "cashier"]
        and u.active == true
        and not is_nil(u.last_login)
        and u.last_login >= ^today_start,
      order_by: [asc: u.role, asc: u.full_name]
    ) |> Repo.all()
  end

  def list_staff_with_phone do
    query = from u in User,
            where: u.role in ["admin", "manager", "cashier"] and not is_nil(u.phone),
            order_by: [asc: u.role, asc: u.full_name]
    Repo.all(query)
  end
  
  @doc """
  Returns the list of active users.
  
  ## Examples
  
      iex> list_active_users()
      [%User{}, ...]
  
  """
  def list_active_users do
    query = from u in User,
            where: u.active == true,
            order_by: [asc: u.username]
    Repo.all(query)
  end
  
  @doc """
  Returns the list of inactive users.
  
  ## Examples
  
      iex> list_inactive_users()
      [%User{}, ...]
  
  """
  def list_inactive_users do
    query = from u in User,
            where: u.active == false,
            order_by: [asc: u.username]
    Repo.all(query)
  end
  
  @doc """
  Authenticates a user using their email or username and password.
  
  ## Examples
  
      iex> authenticate_user("user@example.com", "correct_password")
      {:ok, %User{}}
      
      iex> authenticate_user("user@example.com", "wrong_password")
      {:error, :invalid_credentials}
      
      iex> authenticate_user("nonexistent@example.com", "any_password")
      {:error, :invalid_credentials}
      
      iex> authenticate_user("inactive_user@example.com", "correct_password")
      {:error, :inactive_account}
  
  """
  @max_attempts 5
  @lockout_minutes 15

  def authenticate_user(email_or_username, password) when is_binary(email_or_username) and is_binary(password) do
    user =
      if String.contains?(email_or_username, "@") do
        get_user_by_email(email_or_username)
      else
        get_user_by_username(email_or_username)
      end

    cond do
      is_nil(user) ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      !user.active ->
        Bcrypt.verify_pass(password, user.password_hash)
        {:error, :inactive_account}

      account_locked?(user) ->
        {:error, {:account_locked, user.locked_until}}

      Bcrypt.verify_pass(password, user.password_hash) ->
        reset_failed_attempts(user)
        {:ok, updated_user} = update_last_login(user)
        {:ok, updated_user}

      true ->
        increment_failed_attempts(user)
        {:error, :invalid_credentials}
    end
  end

  def account_locked?(%User{locked_until: nil}), do: false

  def account_locked?(%User{locked_until: locked_until}) do
    NaiveDateTime.compare(NaiveDateTime.utc_now(), locked_until) == :lt
  end

  defp increment_failed_attempts(user) do
    new_attempts = (user.failed_attempts || 0) + 1

    attrs =
      if new_attempts >= @max_attempts do
        locked_until =
          NaiveDateTime.utc_now()
          |> NaiveDateTime.add(@lockout_minutes * 60, :second)
          |> NaiveDateTime.truncate(:second)

        %{failed_attempts: new_attempts, locked_until: locked_until}
      else
        %{failed_attempts: new_attempts}
      end

    user |> User.security_changeset(attrs) |> Repo.update()
  end

  defp reset_failed_attempts(%User{failed_attempts: 0, locked_until: nil}), do: :ok

  defp reset_failed_attempts(user) do
    user
    |> User.security_changeset(%{failed_attempts: 0, locked_until: nil})
    |> Repo.update()
  end

  # ---------------------------------------------------------------------------
  # TOTP / Two-Factor Authentication
  # ---------------------------------------------------------------------------

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
  
  @doc """
  Checks if a user has a specific role.
  
  ## Examples
  
      iex> has_role?(user, "admin")
      true
      
      iex> has_role?(user, "manager")
      false
  
  """
  def has_role?(%User{} = user, role) when is_binary(role) do
    user.role == role
  end
  
  @doc """
  Checks if a user is active.
  
  ## Examples
  
      iex> is_active?(user)
      true
  
  """
  def is_active?(%User{} = user) do
    user.active
  end
  
  @doc """
  Returns users who have logged in within a specified number of days.
  
  ## Examples
  
      iex> list_recently_active_users(30)
      [%User{}, ...]
  
  """
  def list_recently_active_users(days) when is_integer(days) and days > 0 do
    cutoff_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -days * 24 * 60 * 60, :second)
    
    query = from u in User,
            where: u.last_login >= ^cutoff_date,
            order_by: [desc: u.last_login]
    Repo.all(query)
  end
  
  @doc """
  Returns users who have not logged in within a specified number of days.
  
  ## Examples
  
      iex> list_inactive_login_users(30)
      [%User{}, ...]
  
  """
  def list_inactive_login_users(days) when is_integer(days) and days > 0 do
    cutoff_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -days * 24 * 60 * 60, :second)

    query = from u in User,
            where: u.last_login < ^cutoff_date or is_nil(u.last_login),
            order_by: [asc: u.username]
    Repo.all(query)
  end

  def list_users_paginated(page \\ 1) do
    query = from u in User, order_by: [asc: u.role, asc: u.full_name]
    FleetMint.Pagination.paginate(query, page)
  end

  def request_password_reset(email) when is_binary(email) do
    case get_user_by_email(email) do
      nil ->
        {:error, :not_found}
      user ->
        token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
        token_hash = :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)
        expires_at =
          NaiveDateTime.utc_now()
          |> NaiveDateTime.add(3600, :second)
          |> NaiveDateTime.truncate(:second)
        user
        |> User.reset_token_changeset(%{reset_token_hash: token_hash, reset_token_expires_at: expires_at})
        |> Repo.update()
        {:ok, user, token}
    end
  end

  def reset_password_by_token(token, new_password) when is_binary(token) do
    token_hash = :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)
    now = NaiveDateTime.utc_now()
    case Repo.get_by(User, reset_token_hash: token_hash) do
      nil ->
        {:error, :invalid_token}
      %User{reset_token_expires_at: exp} = user ->
        if NaiveDateTime.compare(exp, now) == :lt do
          {:error, :expired_token}
        else
          user
          |> User.password_changeset(%{password: new_password})
          |> Ecto.Changeset.change(reset_token_hash: nil, reset_token_expires_at: nil)
          |> Repo.update()
        end
    end
  end
end

