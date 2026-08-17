defmodule FleetMintWeb.RoutesLiveTest do
  use FleetMintWeb.ConnCase

  import Phoenix.LiveViewTest
  import FleetMint.IdentityFixtures
  import FleetMint.FleetFixtures

  alias FleetMint.Transport.Trips

  test "shows a fare range computed from real operator schedules, not the route's base fare", %{
    conn: conn
  } do
    user = user_fixture()
    operator = operator_fixture()

    route =
      route_fixture(name: "Lusaka - Livingstone Express", fare: "200.00")

    {:ok, _} =
      Trips.create_schedule(%{
        route_id: route.id,
        operator_id: operator.id,
        departure_time: ~T[06:00:00],
        fare: "180.00"
      })

    {:ok, _} =
      Trips.create_schedule(%{
        route_id: route.id,
        operator_id: operator.id,
        departure_time: ~T[14:00:00],
        fare: "220.00"
      })

    {:ok, _view, html} = conn |> log_in_user(user) |> live(~p"/routes")

    assert html =~ "180.00"
    assert html =~ "220.00"
    refute html =~ "ZMW 200.00"
  end

  test "falls back to the route's base fare when it has no schedules yet", %{conn: conn} do
    user = user_fixture()
    route_fixture(name: "Lusaka - Chipata", fare: "310.00")

    {:ok, _view, html} = conn |> log_in_user(user) |> live(~p"/routes")

    assert html =~ "From ZMW 310.00"
  end

  test "status filter patches the list live", %{conn: conn} do
    user = user_fixture()
    route_fixture(name: "Active Corridor", status: "active")
    route_fixture(name: "Inactive Corridor", status: "inactive")

    {:ok, view, html} = conn |> log_in_user(user) |> live(~p"/routes")
    assert html =~ "Active Corridor"
    assert html =~ "Inactive Corridor"

    html = view |> element("#status-filters a", "Active") |> render_click()

    assert html =~ "Active Corridor"
    refute html =~ "Inactive Corridor"
  end
end
