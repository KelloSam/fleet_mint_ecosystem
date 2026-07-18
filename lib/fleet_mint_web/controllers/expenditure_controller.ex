defmodule FleetMintWeb.ExpenditureController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Finance.Expenditure
  alias FleetMint.Identity.Authorization
  alias FleetMint.Administration

  # Any authenticated staff can log an expenditure, but editing or
  # deleting one after the fact needs manager+ oversight — otherwise the
  # same cashier who padded an expense could also erase or rewrite it
  # with nobody else in the loop.
  plug :require_admin_or_manager when action in [:edit, :update, :delete]

  def index(conn, _params) do
    expenditures =
      Finance.list_expenditures(organisation_id: conn.assigns.organisation_scope)
      |> FleetMint.Repo.preload([:cashing_report, :created_by])
    render(conn, :index, expenditures: expenditures)
  end

  def new(conn, _params) do
    changeset = Finance.change_expenditure(%Expenditure{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"expenditure" => expenditure_params}) do
    actor = conn.assigns.current_user

    case Finance.create_expenditure(expenditure_params, actor.id) do
      {:ok, expenditure} ->
        Administration.log("expenditure_created",
          actor_id: actor.id,
          actor_email: actor.email,
          target_type: "Expenditure",
          target_id: expenditure.id,
          metadata: %{
            amount: expenditure.amount,
            description: expenditure.description,
            cashing_report_id: expenditure.cashing_report_id
          },
          ip_address: client_ip(conn)
        )

        conn
        |> put_flash(:info, "Expenditure created successfully.")
        |> redirect(to: ~p"/expenditures/#{expenditure}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    expenditure = Finance.get_expenditure!(id) |> FleetMint.Repo.preload([:created_by, :updated_by])

    with_organisation_access(conn, expenditure.cashing_report.bus, ~p"/expenditures", fn conn ->
      render(conn, :show, expenditure: expenditure)
    end)
  end

  def edit(conn, %{"id" => id}) do
    expenditure = Finance.get_expenditure!(id)

    with_organisation_access(conn, expenditure.cashing_report.bus, ~p"/expenditures", fn conn ->
      changeset = Finance.change_expenditure(expenditure)
      render(conn, :edit, expenditure: expenditure, changeset: changeset)
    end)
  end

  def update(conn, %{"id" => id, "expenditure" => expenditure_params}) do
    expenditure = Finance.get_expenditure!(id)
    actor = conn.assigns.current_user
    before = %{amount: expenditure.amount, description: expenditure.description}

    with_organisation_access(conn, expenditure.cashing_report.bus, ~p"/expenditures", fn conn ->
      case Finance.update_expenditure(expenditure, expenditure_params, actor.id) do
        {:ok, expenditure} ->
          Administration.log("expenditure_updated",
            actor_id: actor.id,
            actor_email: actor.email,
            target_type: "Expenditure",
            target_id: expenditure.id,
            metadata: %{
              from: before,
              to: %{amount: expenditure.amount, description: expenditure.description}
            },
            ip_address: client_ip(conn)
          )

          conn
          |> put_flash(:info, "Expenditure updated successfully.")
          |> redirect(to: ~p"/expenditures/#{expenditure}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit, expenditure: expenditure, changeset: changeset)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    expenditure = Finance.get_expenditure!(id)
    actor = conn.assigns.current_user

    with_organisation_access(conn, expenditure.cashing_report.bus, ~p"/expenditures", fn conn ->
      # Snapshot before archiving — the audit log entry has to carry the
      # full record on its own since the row disappears from every
      # normal view the moment this succeeds.
      {:ok, _expenditure} = Finance.delete_expenditure(expenditure, actor.id)

      Administration.log("expenditure_deleted",
        actor_id: actor.id,
        actor_email: actor.email,
        target_type: "Expenditure",
        target_id: expenditure.id,
        metadata: %{
          amount: expenditure.amount,
          description: expenditure.description,
          cashing_report_id: expenditure.cashing_report_id
        },
        ip_address: client_ip(conn)
      )

      conn
      |> put_flash(:info, "Expenditure deleted successfully.")
      |> redirect(to: ~p"/expenditures")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp with_organisation_access(conn, bus, fallback_path, fun) do
    organisation_id = bus && bus.organisation_id

    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That expenditure belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end

  defp require_admin_or_manager(conn, _opts) do
    if Authorization.authorized?(conn.assigns.current_user, ["platform_admin", "tenant_admin", "manager"]) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorised to perform this action.")
      |> redirect(to: ~p"/expenditures")
      |> halt()
    end
  end
end
