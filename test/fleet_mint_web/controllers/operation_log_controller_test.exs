defmodule FleetMintWeb.OperationLogControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  alias FleetMint.Administration

  describe "tenant scoping" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      staff_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)
      staff_b = user_fixture(role: "cashier", organisation_id: org_b.organisation_id)

      {:ok, log_a} =
        Administration.create_operation_log(%{
          "date" => Date.to_iso8601(Date.utc_today()),
          "title" => "Org A incident",
          "logged_by_id" => staff_a.id,
          "organisation_id" => org_a.organisation_id
        })

      {:ok, log_b} =
        Administration.create_operation_log(%{
          "date" => Date.to_iso8601(Date.utc_today()),
          "title" => "Org B incident",
          "logged_by_id" => staff_b.id,
          "organisation_id" => org_b.organisation_id
        })

      %{org_a: org_a, log_a: log_a, log_b: log_b, staff_a: staff_a}
    end

    test "index only lists the caller's own organisation's log entries", %{
      conn: conn,
      staff_a: staff_a,
      log_a: log_a,
      log_b: log_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/operation_logs")
      html_response(conn, 200)

      listed_ids = Enum.map(conn.assigns.paged.entries, & &1.id)
      assert log_a.id in listed_ids
      refute log_b.id in listed_ids
    end

    test "prohibited: cannot view another organisation's log entry", %{
      conn: conn,
      staff_a: staff_a,
      log_b: log_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/operation_logs/#{log_b}")

      assert redirected_to(conn) == ~p"/operation_logs"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "prohibited: cannot delete another organisation's log entry", %{
      conn: conn,
      staff_a: staff_a,
      log_b: log_b
    } do
      conn = conn |> log_in_user(staff_a) |> delete(~p"/operation_logs/#{log_b}")

      assert redirected_to(conn) == ~p"/operation_logs"
      assert FleetMint.Repo.reload(log_b)
    end

    test "authorised: create forces the caller's own organisation regardless of submitted value",
         %{conn: conn, staff_a: staff_a, org_a: org_a} do
      conn =
        conn
        |> log_in_user(staff_a)
        |> post(~p"/operation_logs", %{
          "operation_log" => %{
            "date" => Date.to_iso8601(Date.utc_today()),
            "title" => "Spoof attempt",
            "organisation_id" => 999_999
          }
        })

      assert %{id: id} = redirected_params(conn)
      log = Administration.get_operation_log!(id)
      assert log.organisation_id == org_a.organisation_id
    end
  end
end
