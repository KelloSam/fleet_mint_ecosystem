defmodule FleetMintWeb.ComplaintController do
  use FleetMintWeb, :controller
  alias FleetMint.Administration
  alias FleetMint.Identity.Authorization

  # Public: show submission form
  def new(conn, params) do
    changeset =
      Administration.change_complaint(%Administration.Complaint{
        type: params["type"] || "complaint"
      })

    render(conn, :new, changeset: changeset, prefill_ref: params["ref"])
  end

  # Public: submit complaint or suggestion
  def create(conn, %{"complaint" => complaint_params}) do
    case Administration.create_complaint(complaint_params) do
      {:ok, _complaint} ->
        conn
        |> put_flash(
          :info,
          "Thank you! Your #{complaint_params["type"] || "submission"} has been received. We will review it shortly."
        )
        |> redirect(to: ~p"/feedback/thank_you")

      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          prefill_ref: complaint_params["booking_reference"]
        )
    end
  end

  def thank_you(conn, _params) do
    render(conn, :thank_you)
  end

  # Staff: list all complaints and suggestions
  def index(conn, params) do
    complaints =
      Administration.list_complaints(
        type: params["type"],
        status: params["status"],
        organisation_id: conn.assigns.organisation_scope
      )

    pending_count = Administration.count_pending_complaints()

    render(conn, :index,
      complaints: complaints,
      pending_count: pending_count,
      type_filter: params["type"],
      status_filter: params["status"]
    )
  end

  # Staff: view single complaint
  def show(conn, %{"id" => id}) do
    complaint = Administration.get_complaint!(id)

    with_organisation_access(conn, complaint.organisation_id, fn conn ->
      render(conn, :show, complaint: complaint)
    end)
  end

  # Staff: resolve or update status
  def update(conn, %{"id" => id, "complaint" => params}) do
    complaint = Administration.get_complaint!(id)

    with_organisation_access(conn, complaint.organisation_id, fn conn ->
      update_params = Map.merge(params, %{"reviewed_by_id" => conn.assigns.current_user.id})

      case Administration.update_complaint(complaint, update_params) do
        {:ok, complaint} ->
          conn
          |> put_flash(:info, "Updated successfully.")
          |> redirect(to: ~p"/complaints/#{complaint}")

        {:error, changeset} ->
          render(conn, :show, complaint: complaint, changeset: changeset)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    complaint = Administration.get_complaint!(id)

    with_organisation_access(conn, complaint.organisation_id, fn conn ->
      {:ok, _} = Administration.delete_complaint(complaint)

      conn
      |> put_flash(:info, "Record deleted.")
      |> redirect(to: ~p"/complaints")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp with_organisation_access(conn, organisation_id, fun) do
    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That record belongs to a different organisation.")
      |> redirect(to: ~p"/complaints")
    end
  end
end
