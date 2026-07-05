defmodule FleetMint.Identity.Authentication do
  @moduledoc """
  Login (email/username + password), account lockout, and password reset.
  User CRUD lives in `FleetMint.Identity.Users`; TOTP in
  `FleetMint.Identity.TwoFactor`.
  """

  alias FleetMint.Repo
  alias FleetMint.Identity.User
  alias FleetMint.Identity.Users

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
        Users.get_user_by_email(email_or_username)
      else
        Users.get_user_by_username(email_or_username)
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

  def update_last_login(%User{} = user) do
    user
    |> Ecto.Changeset.change(last_login: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> Repo.update()
  end

  def request_password_reset(email) when is_binary(email) do
    case Users.get_user_by_email(email) do
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
