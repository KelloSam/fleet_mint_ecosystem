defmodule FleetMint.IdentityFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FleetMint.Identity` context.
  """

  @doc """
  Defaults role to "platform_admin" (no organisation) or "tenant_admin"
  (organisation_id given) so the fixture satisfies User's role/organisation
  pairing invariant without every caller having to pick a role explicitly.
  Pass `role:` to override.
  """
  def user_fixture(attrs \\ %{}) do
    n = System.unique_integer([:positive])
    attrs = Map.new(attrs)
    default_role = if Map.get(attrs, :organisation_id), do: "tenant_admin", else: "platform_admin"

    {:ok, user} =
      attrs
      |> Enum.into(%{
        username: "user#{n}",
        email: "user#{n}@example.com",
        password: "Password123!secure",
        role: default_role,
        full_name: "Test User #{n}",
        active: true
      })
      |> FleetMint.Identity.Users.create_user()

    user
  end
end
