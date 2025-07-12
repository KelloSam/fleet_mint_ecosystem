defmodule BusCashingSystem.Accounts do
  @moduledoc """
  The Accounts context.
  
  This context handles operations related to user management, authentication,
  and authorization. It provides functions to create, read, update, and delete users,
  as well as specialized functions for authentication and security.
  """
  
  import Ecto.Query, warn: false
  alias BusCashingSystem.Repo
  alias BusCashingSystem.Accounts.User
  
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
  def authenticate_user(email_or_username, password) when is_binary(email_or_username) and is_binary(password) do
    user = 
      if String.contains?(email_or_username, "@") do
        get_user_by_email(email_or_username)
      else
        get_user_by_username(email_or_username)
      end
      
    cond do
      # User not found
      is_nil(user) ->
        # Use constant-time comparison to avoid timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
        
      # User exists but is inactive
      user && !user.active ->
        # Still verify the password to avoid timing attacks
        Bcrypt.verify_pass(password, user.password_hash)
        {:error, :inactive_account}
        
      # User exists and is active - verify password
      user && user.active ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          # Update the last login timestamp
          {:ok, updated_user} = update_last_login(user)
          {:ok, updated_user}
        else
          {:error, :invalid_credentials}
        end
    end
  end
  
  @doc """
  Updates the last login timestamp for a user.
  
  ## Examples
  
      iex> update_last_login(user)
      {:ok, %User{}}
  
  """
  def update_last_login(%User{} = user) do
    update_user(user, %{last_login: NaiveDateTime.utc_now()})
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
end

