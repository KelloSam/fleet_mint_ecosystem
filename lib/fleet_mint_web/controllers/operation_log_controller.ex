defmodule FleetMintWeb.OperationLogController do
  use FleetMintWeb, :controller

  alias FleetMint.Administration
  alias FleetMint.Administration.OperationLog

  def index(conn, _params) do
    logs = Administration.list_operation_logs()
    render(conn, :index, logs: logs)
  end

  def new(conn, _params) do
    changeset = Administration.change_operation_log(%OperationLog{date: Date.utc_today()})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"operation_log" => params}) do
    params_with_user = Map.put(params, "logged_by_id", conn.assigns.current_user.id)
    case Administration.create_operation_log(params_with_user) do
      {:ok, log} ->
        conn |> put_flash(:info, "Log entry created.") |> redirect(to: ~p"/operation_logs/#{log}")
      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    log = Administration.get_operation_log!(id)
    render(conn, :show, log: log)
  end

  def edit(conn, %{"id" => id}) do
    log = Administration.get_operation_log!(id)
    changeset = Administration.change_operation_log(log)
    render(conn, :edit, log: log, changeset: changeset)
  end

  def update(conn, %{"id" => id, "operation_log" => params}) do
    log = Administration.get_operation_log!(id)
    case Administration.update_operation_log(log, params) do
      {:ok, log} ->
        conn |> put_flash(:info, "Log updated.") |> redirect(to: ~p"/operation_logs/#{log}")
      {:error, changeset} ->
        render(conn, :edit, log: log, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    log = Administration.get_operation_log!(id)
    {:ok, _} = Administration.delete_operation_log(log)
    conn |> put_flash(:info, "Log entry deleted.") |> redirect(to: ~p"/operation_logs")
  end
end
