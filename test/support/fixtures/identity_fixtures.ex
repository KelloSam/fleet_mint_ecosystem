defmodule FleetMint.IdentityFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FleetMint.Identity` context.
  """

  def user_fixture(attrs \\ %{}) do
    n = System.unique_integer([:positive])

    {:ok, user} =
      attrs
      |> Enum.into(%{
        username: "user#{n}",
        email: "user#{n}@example.com",
        password: "Password123!secure",
        role: "admin",
        full_name: "Test User #{n}",
        active: true
      })
      |> FleetMint.Identity.Users.create_user()

    user
  end
end
