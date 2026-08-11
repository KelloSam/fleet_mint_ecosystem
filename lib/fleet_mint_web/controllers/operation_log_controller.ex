defmodule FleetMintWeb.OperationLogController do
  use FleetMintWeb, :controller

  alias FleetMint.Administration
  alias FleetMint.Administration.OperationLog
  alias FleetMint.Identity.Authorization

  def index(conn, _params) do
    logs = Administration.list_operation_logs(organisation_id: conn.assigns.organisation_scope)
    render(conn, :index, logs: logs)
  end

  def new(conn, _params) do
    changeset = Administration.change_operation_log(%OperationLog{date: Date.utc_today()})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"operation_log" => params}) do
    params =
      params
      |> Map.put("logged_by_id", conn.assigns.current_user.id)
      |> force_organisation_scope(conn.assigns.organisation_scope)

    case Administration.create_operation_log(params) do
      {:ok, log} ->
        conn |> put_flash(:info, "Log entry created.") |> redirect(to: ~p"/operation_logs/#{log}")

      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    log = Administration.get_operation_log!(id)

    with_organisation_access(conn, log.organisation_id, ~p"/operation_logs", fn conn ->
      render(conn, :show, log: log)
    end)
  end

  def edit(conn, %{"id" => id}) do
    log = Administration.get_operation_log!(id)

    with_organisation_access(conn, log.organisation_id, ~p"/operation_logs", fn conn ->
      changeset = Administration.change_operation_log(log)
      render(conn, :edit, log: log, changeset: changeset)
    end)
  end

  def update(conn, %{"id" => id, "operation_log" => params}) do
    log = Administration.get_operation_log!(id)

    with_organisation_access(conn, log.organisation_id, ~p"/operation_logs", fn conn ->
      case Administration.update_operation_log(log, params) do
        {:ok, log} ->
          conn |> put_flash(:info, "Log updated.") |> redirect(to: ~p"/operation_logs/#{log}")

        {:error, changeset} ->
          render(conn, :edit, log: log, changeset: changeset)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    log = Administration.get_operation_log!(id)

    with_organisation_access(conn, log.organisation_id, ~p"/operation_logs", fn conn ->
      {:ok, _} = Administration.delete_operation_log(log)
      conn |> put_flash(:info, "Log entry deleted.") |> redirect(to: ~p"/operation_logs")
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
      |> put_flash(:error, "That log entry belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
