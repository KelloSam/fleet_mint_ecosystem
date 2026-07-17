defmodule FleetMint.Identity.AuthorizationTest do
  use ExUnit.Case, async: true

  alias FleetMint.Identity.{Authorization, User}

  describe "platform_level?/1" do
    test "true when operator_id is nil" do
      assert Authorization.platform_level?(%User{operator_id: nil})
    end

    test "false when operator_id is set" do
      refute Authorization.platform_level?(%User{operator_id: 7})
    end
  end

  describe "can_access_operator?/2" do
    test "platform-level users can access any operator's data" do
      user = %User{operator_id: nil}
      assert Authorization.can_access_operator?(user, 7)
      assert Authorization.can_access_operator?(user, 99)
    end

    test "tenant staff can access only their own operator's data" do
      user = %User{operator_id: 7}
      assert Authorization.can_access_operator?(user, 7)
      refute Authorization.can_access_operator?(user, 3)
    end
  end
end
