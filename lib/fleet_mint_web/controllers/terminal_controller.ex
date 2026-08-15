defmodule FleetMintWeb.TerminalController do
  use FleetMintWeb, :controller

  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Fleet.Terminal
  alias FleetMint.Identity.Authorization

  def index(conn, _params) do
    terminals = Fleet.list_terminals(conn.assigns.organisation_scope)
    render(conn, :index, terminals: terminals)
  end

  def new(conn, _params) do
    changeset = Fleet.change_terminal(%Terminal{})
    render(conn, :new, changeset: changeset, branches: allowed_branches(conn))
  end

  def create(conn, %{"terminal" => terminal_params}) do
    branches = allowed_branches(conn)

    if branch_allowed?(branches, terminal_params["branch_id"]) do
      case Fleet.create_terminal(terminal_params) do
        {:ok, terminal} ->
          conn
          |> put_flash(:info, "Terminal #{terminal.name} added successfully.")
          |> redirect(to: ~p"/terminals/#{terminal}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :new, changeset: changeset, branches: branches)
      end
    else
      changeset = Fleet.change_terminal(%Terminal{})

      conn
      |> put_flash(:error, "That branch is not available to you.")
      |> render(:new, changeset: changeset, branches: branches)
    end
  end

  def show(conn, %{"id" => id}) do
    terminal = Fleet.get_terminal!(id)

    with_organisation_access(conn, terminal.branch.organisation_id, ~p"/terminals", fn conn ->
      render(conn, :show, terminal: terminal)
    end)
  end

  def edit(conn, %{"id" => id}) do
    terminal = Fleet.get_terminal!(id)

    with_organisation_access(conn, terminal.branch.organisation_id, ~p"/terminals", fn conn ->
      changeset = Fleet.change_terminal(terminal)

      render(conn, :edit,
        terminal: terminal,
        changeset: changeset,
        branches: allowed_branches(conn)
      )
    end)
  end

  def update(conn, %{"id" => id, "terminal" => terminal_params}) do
    terminal = Fleet.get_terminal!(id)

    with_organisation_access(conn, terminal.branch.organisation_id, ~p"/terminals", fn conn ->
      branches = allowed_branches(conn)

      if branch_allowed?(branches, terminal_params["branch_id"] || terminal.branch_id) do
        case Fleet.update_terminal(terminal, terminal_params) do
          {:ok, terminal} ->
            conn
            |> put_flash(:info, "Terminal #{terminal.name} updated successfully.")
            |> redirect(to: ~p"/terminals/#{terminal}")

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, :edit, terminal: terminal, changeset: changeset, branches: branches)
        end
      else
        conn
        |> put_flash(:error, "That branch is not available to you.")
        |> redirect(to: ~p"/terminals/#{terminal}")
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    terminal = Fleet.get_terminal!(id)

    with_organisation_access(conn, terminal.branch.organisation_id, ~p"/terminals", fn conn ->
      {:ok, _terminal} = Fleet.delete_terminal(terminal)

      conn
      |> put_flash(:info, "Terminal #{terminal.name} removed.")
      |> redirect(to: ~p"/terminals")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp allowed_branches(conn), do: Fleet.list_branches(conn.assigns.organisation_scope)

  defp branch_allowed?(branches, branch_id) do
    branch_id = to_string(branch_id)
    Enum.any?(branches, &(to_string(&1.id) == branch_id))
  end

  defp with_organisation_access(conn, organisation_id, fallback_path, fun) do
    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That terminal belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
