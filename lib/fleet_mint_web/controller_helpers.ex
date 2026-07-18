defmodule FleetMintWeb.ControllerHelpers do
  @moduledoc """
  Small helpers imported into every controller (see `FleetMintWeb.controller/0`).
  """

  @doc """
  The caller's IP, preferring a reverse proxy's `x-forwarded-for` over
  the raw socket address. Used for audit-log entries.
  """
  def client_ip(conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip
      [] -> to_string(:inet.ntoa(conn.remote_ip))
    end
  end
end
