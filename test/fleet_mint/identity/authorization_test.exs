defmodule FleetMint.Identity.AuthorizationTest do
  use ExUnit.Case, async: true

  alias FleetMint.Identity.{Authorization, User}

  describe "platform_level?/1" do
    test "true when organisation_id is nil" do
      assert Authorization.platform_level?(%User{organisation_id: nil})
    end

    test "false when organisation_id is set" do
      refute Authorization.platform_level?(%User{organisation_id: 7})
    end
  end

  describe "can_access_organisation?/2" do
    test "platform-level users can access any organisation's data" do
      user = %User{organisation_id: nil}
      assert Authorization.can_access_organisation?(user, 7)
      assert Authorization.can_access_organisation?(user, 99)
    end

    test "tenant staff can access only their own organisation's data" do
      user = %User{organisation_id: 7}
      assert Authorization.can_access_organisation?(user, 7)
      refute Authorization.can_access_organisation?(user, 3)
    end
  end
end
