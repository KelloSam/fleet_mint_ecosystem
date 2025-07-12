defmodule BusCashingSystem.Auth.Guardian do
  use Guardian, otp_app: :bus_cashing_system

  alias BusCashingSystem.Accounts
  alias BusCashingSystem.Accounts.User

  @doc """
  Get the subject for the token from the resource (user)
  """
  def subject_for_token(%User{id: id}, _claims) do
    # Convert the user id to a string for the token
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :resource_not_found}
  end

  @doc """
  Load the resource (user) from the claims in the token
  """
  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      %User{} = user -> {:ok, user}
      nil -> {:error, :resource_not_found}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end

  @doc """
  Generate an access token for a user
  """
  def authenticate(email, password) do
    case Accounts.get_user_by_email(email) do
      nil ->
        # Don't reveal that the email doesn't exist
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
      
      user ->
        case Bcrypt.verify_pass(password, user.password_hash) do
          true -> create_token(user)
          false -> {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Create a token for a user
  """
  def create_token(user) do
    {:ok, token, _claims} = encode_and_sign(user, %{}, token_type: "access")
    {:ok, user, token}
  end
end

