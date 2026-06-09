defmodule FleetMintWeb.ExpenditureController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Finance.Expenditure

  def index(conn, _params) do
    # Preload cashing_report association for each expenditure
    expenditures = Finance.list_expenditures() |> FleetMint.Repo.preload(:cashing_report)
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
    # Preload the cashing_report association to avoid KeyError with :id in templates
    expenditure = id |> Finance.get_expenditure!() |> FleetMint.Repo.preload(:cashing_report)
    render(conn, :show, expenditure: expenditure)
  end

  def edit(conn, %{"id" => id}) do
    # Preload the cashing_report association
    expenditure = id |> Finance.get_expenditure!() |> FleetMint.Repo.preload(:cashing_report)
    changeset = Finance.change_expenditure(expenditure)
    render(conn, :edit, expenditure: expenditure, changeset: changeset)
  end

  def update(conn, %{"id" => id, "expenditure" => expenditure_params}) do
    # Preload the cashing_report association
    expenditure = id |> Finance.get_expenditure!() |> FleetMint.Repo.preload(:cashing_report)

    case Finance.update_expenditure(expenditure, expenditure_params) do
      {:ok, expenditure} ->
        conn
        |> put_flash(:info, "Expenditure updated successfully.")
        |> redirect(to: ~p"/expenditures/#{expenditure}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, expenditure: expenditure, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    expenditure = Finance.get_expenditure!(id)
    {:ok, _expenditure} = Finance.delete_expenditure(expenditure)

    conn
    |> put_flash(:info, "Expenditure deleted successfully.")
    |> redirect(to: ~p"/expenditures")
  end
end
