defmodule FleetMint.HRTest do
  use FleetMint.DataCase

  alias FleetMint.HR

  import FleetMint.HRFixtures
  import FleetMint.FleetFixtures

  describe "list_drivers/1 tenant scoping" do
    test "organisation_id filters to that organisation's drivers only" do
      org_a = operator_fixture()
      org_b = operator_fixture()

      driver_a = driver_fixture(organisation_id: org_a.organisation_id)
      driver_fixture(organisation_id: org_b.organisation_id)

      result = HR.list_drivers(organisation_id: org_a.organisation_id)

      assert Enum.map(result, & &1.id) == [driver_a.id]
    end

    test ":all bypasses the organisation filter" do
      org_a = operator_fixture()
      org_b = operator_fixture()

      driver_fixture(organisation_id: org_a.organisation_id)
      driver_fixture(organisation_id: org_b.organisation_id)

      result = HR.list_drivers(organisation_id: :all)

      assert length(result) >= 2
    end
  end
end
