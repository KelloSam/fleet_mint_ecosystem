defmodule FleetMint.Identity.Guardian do
  use Guardian, otp_app: :fleet_mint

  alias FleetMint.Identity
  alias FleetMint.Identity.User

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
    case Identity.get_user(id) do
      %User{active: true} = user -> {:ok, user}
      %User{active: false} -> {:error, :inactive_account}
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
    case Identity.authenticate_user(email, password) do
      {:ok, user} -> create_token(user)
      error -> error
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

