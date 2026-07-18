defmodule FleetMintWeb.ExpenditureController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Finance.Expenditure
  alias FleetMint.Identity.Authorization

  def index(conn, _params) do
    expenditures =
      Finance.list_expenditures(organisation_id: conn.assigns.organisation_scope)
      |> FleetMint.Repo.preload(:cashing_report)
    render(conn, :index, expenditures: expenditures)
  end

  def new(conn, _params) do
    changeset = Finance.change_expenditure(%Expenditure{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"expenditure" => expenditure_params}) do
    case Finance.create_expenditure(expenditure_params) do
      {:ok, expenditure} ->
        conn
        |> put_flash(:info, "Expenditure created successfully.")
        |> redirect(to: ~p"/expenditures/#{expenditure}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    expenditure = Finance.get_expenditure!(id)

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

    with_organisation_access(conn, expenditure.cashing_report.bus, ~p"/expenditures", fn conn ->
      case Finance.update_expenditure(expenditure, expenditure_params) do
        {:ok, expenditure} ->
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

    with_organisation_access(conn, expenditure.cashing_report.bus, ~p"/expenditures", fn conn ->
      {:ok, _expenditure} = Finance.delete_expenditure(expenditure)

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
end
