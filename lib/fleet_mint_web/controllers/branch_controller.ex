defmodule FleetMintWeb.BranchController do
  use FleetMintWeb, :controller

  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Fleet.Branch
  alias FleetMint.Identity.Authorization

  def index(conn, _params) do
    branches = Fleet.list_branches(conn.assigns.organisation_scope)
    render(conn, :index, branches: branches)
  end

  def new(conn, _params) do
    changeset = Fleet.change_branch(%Branch{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"branch" => branch_params}) do
    branch_params = force_organisation_scope(branch_params, conn.assigns.organisation_scope)

    case Fleet.create_branch(branch_params) do
      {:ok, branch} ->
        conn
        |> put_flash(:info, "Branch #{branch.name} added successfully.")
        |> redirect(to: ~p"/branches/#{branch}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    branch = Fleet.get_branch!(id)

    with_organisation_access(conn, branch.organisation_id, ~p"/branches", fn conn ->
      terminals = Fleet.list_terminals_for_branch(branch.id)
      render(conn, :show, branch: branch, terminals: terminals)
    end)
  end

  def edit(conn, %{"id" => id}) do
    branch = Fleet.get_branch!(id)

    with_organisation_access(conn, branch.organisation_id, ~p"/branches", fn conn ->
      changeset = Fleet.change_branch(branch)
      render(conn, :edit, branch: branch, changeset: changeset)
    end)
  end

  def update(conn, %{"id" => id, "branch" => branch_params}) do
    branch = Fleet.get_branch!(id)

    with_organisation_access(conn, branch.organisation_id, ~p"/branches", fn conn ->
      case Fleet.update_branch(branch, branch_params) do
        {:ok, branch} ->
          conn
          |> put_flash(:info, "Branch #{branch.name} updated successfully.")
          |> redirect(to: ~p"/branches/#{branch}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit, branch: branch, changeset: changeset)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    branch = Fleet.get_branch!(id)

    with_organisation_access(conn, branch.organisation_id, ~p"/branches", fn conn ->
      {:ok, _branch} = Fleet.delete_branch(branch)

      conn
      |> put_flash(:info, "Branch #{branch.name} removed.")
      |> redirect(to: ~p"/branches")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp force_organisation_scope(params, :all), do: params

  defp force_organisation_scope(params, organisation_id),
    do: Map.put(params, "organisation_id", organisation_id)

  defp with_organisation_access(conn, organisation_id, fallback_path, fun) do
    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That branch belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
