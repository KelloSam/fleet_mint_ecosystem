defmodule FleetMintWeb.ComplaintControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures
  import FleetMint.TicketingFixtures

  alias FleetMint.Administration

  describe "public submission — organisation derivation" do
    test "derives organisation_id from a booking_reference that matches a real booking" do
      org_a = operator_fixture()
      schedule_a = schedule_fixture(operator_id: org_a.id)
      booking_a = booking_fixture(schedule: schedule_a)

      {:ok, complaint} =
        Administration.create_complaint(%{
          "type" => "complaint",
          "passenger_name" => "Jane Doe",
          "description" => "The bus arrived over an hour late for no reason.",
          "booking_reference" => booking_a.booking_reference
        })

      assert complaint.organisation_id == org_a.organisation_id
    end

    test "leaves organisation_id nil when no booking_reference is given" do
      {:ok, complaint} =
        Administration.create_complaint(%{
          "type" => "suggestion",
          "passenger_name" => "Jane Doe",
          "description" => "Please add more buses on this route please."
        })

      assert is_nil(complaint.organisation_id)
    end

    test "leaves organisation_id nil when booking_reference doesn't match any booking" do
      {:ok, complaint} =
        Administration.create_complaint(%{
          "type" => "complaint",
          "passenger_name" => "Jane Doe",
          "description" => "Reference does not correspond to any booking in this test.",
          "booking_reference" => "BK-DOES-NOT-EXIST"
        })

      assert is_nil(complaint.organisation_id)
    end

    test "ignores a client-supplied organisation_id — it cannot be spoofed" do
      other_org = operator_fixture()

      {:ok, complaint} =
        Administration.create_complaint(%{
          "type" => "complaint",
          "passenger_name" => "Jane Doe",
          "description" => "Attempting to spoof the organisation via a direct attribute.",
          "organisation_id" => other_org.organisation_id
        })

      assert is_nil(complaint.organisation_id)
    end
  end

  describe "tenant scoping" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      schedule_a = schedule_fixture(operator_id: org_a.id)
      schedule_b = schedule_fixture(operator_id: org_b.id)

      booking_a = booking_fixture(schedule: schedule_a)
      booking_b = booking_fixture(schedule: schedule_b)

      {:ok, complaint_a} =
        Administration.create_complaint(%{
          "type" => "complaint",
          "passenger_name" => "Passenger A",
          "description" => "Complaint about organisation A's service quality.",
          "booking_reference" => booking_a.booking_reference
        })

      {:ok, complaint_b} =
        Administration.create_complaint(%{
          "type" => "complaint",
          "passenger_name" => "Passenger B",
          "description" => "Complaint about organisation B's service quality.",
          "booking_reference" => booking_b.booking_reference
        })

      staff_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)
      platform_admin = user_fixture(organisation_id: nil)

      %{
        complaint_a: complaint_a,
        complaint_b: complaint_b,
        staff_a: staff_a,
        platform_admin: platform_admin
      }
    end

    test "index only lists the caller's own organisation's complaints", %{
      conn: conn,
      staff_a: staff_a,
      complaint_a: complaint_a,
      complaint_b: complaint_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/complaints")
      html_response(conn, 200)

      listed_ids = Enum.map(conn.assigns.complaints, & &1.id)
      assert complaint_a.id in listed_ids
      refute complaint_b.id in listed_ids
    end

    test "prohibited: cannot view another organisation's complaint", %{
      conn: conn,
      staff_a: staff_a,
      complaint_b: complaint_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/complaints/#{complaint_b}")

      assert redirected_to(conn) == ~p"/complaints"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "platform_admin can view any organisation's complaint", %{
      conn: conn,
      platform_admin: platform_admin,
      complaint_b: complaint_b
    } do
      conn = conn |> log_in_user(platform_admin) |> get(~p"/complaints/#{complaint_b}")
      assert html_response(conn, 200)
    end
  end
end
