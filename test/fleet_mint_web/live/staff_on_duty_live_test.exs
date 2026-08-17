defmodule FleetMintWeb.StaffOnDutyLiveTest do
  use FleetMintWeb.ConnCase

  import Phoenix.LiveViewTest
  import FleetMint.IdentityFixtures
  import FleetMint.FleetFixtures

  alias FleetMint.Identity.Users

  # user_fixture/1 goes through User.registration_changeset/2, which
  # deliberately doesn't allow setting last_login (nobody should be able
  # to self-register as already on duty) - so marking a fixture user
  # on-duty for these tests takes a real update, same as a live login
  # would.
  defp mark_on_duty(user, now) do
    {:ok, user} = Users.update_user(user, %{last_login: now})
    user
  end

  setup do
    org = operator_fixture()

    %{
      now: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      org_id: org.organisation_id
    }
  end

  test "renders staff who logged in today, with their real name and role", %{
    conn: conn,
    now: now,
    org_id: org_id
  } do
    viewer =
      user_fixture(organisation_id: org_id, role: "cashier") |> mark_on_duty(now)

    user_fixture(full_name: "Jane On Duty", role: "cashier", organisation_id: org_id)
    |> mark_on_duty(now)

    {:ok, _view, html} = conn |> log_in_user(viewer) |> live(~p"/staff/on-duty")

    assert html =~ "Jane On Duty"
    assert html =~ "2 staff currently on duty"
  end

  test "search filters the list live without a page reload", %{
    conn: conn,
    now: now,
    org_id: org_id
  } do
    viewer =
      user_fixture(organisation_id: org_id, role: "cashier") |> mark_on_duty(now)

    user_fixture(full_name: "Alice Cashier", role: "cashier", organisation_id: org_id)
    |> mark_on_duty(now)

    user_fixture(full_name: "Bob Manager", role: "manager", organisation_id: org_id)
    |> mark_on_duty(now)

    {:ok, view, _html} = conn |> log_in_user(viewer) |> live(~p"/staff/on-duty")

    html = view |> element("form") |> render_change(%{"q" => "alice"})

    assert html =~ "Alice Cashier"
    refute html =~ "Bob Manager"
  end
end
