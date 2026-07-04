defmodule FleetMintWeb.TrackingController do
  use FleetMintWeb, :controller
  alias FleetMint.Transport.Boarding

  plug :put_layout, html: {FleetMintWeb.Layouts, :public}

  # GET /track
  def index(conn, %{"ref" => ref}) when ref != "" do
    case Boarding.track_by_booking_reference(String.upcase(String.trim(ref))) do
      {:ok, result} ->
        render(conn, :result, result: result, ref: ref)
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "No booking found with reference \"#{ref}\". Check the reference and try again.")
        |> render(:index, ref: ref)
    end
  end

  def index(conn, _params) do
    render(conn, :index, ref: "")
  end
end
