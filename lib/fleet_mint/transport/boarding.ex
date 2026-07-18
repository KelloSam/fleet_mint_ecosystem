defmodule FleetMint.Transport.Boarding do
  import Ecto.Query
  alias FleetMint.Repo
  alias FleetMint.Transport.Boarding.BusCheckpoint
  alias FleetMint.Transport.Ticketing.{Booking, Ticket}
  alias FleetMint.Transport.Trips

  # ── Ticket validation / boarding ────────────────────────────────────────

  def validate_ticket(ticket_number, _mode \\ :static) do
    case Repo.get_by(Ticket, ticket_number: ticket_number) |> Repo.preload(booking: [:schedule]) do
      nil -> {:error, :not_found}
      %Ticket{status: "boarded"} -> {:error, :already_boarded}
      %Ticket{status: "cancelled"} -> {:error, :cancelled}
      %Ticket{booking: %Booking{status: "cancelled"}} -> {:error, :booking_cancelled}
      %Ticket{expires_at: exp} = ticket when not is_nil(exp) ->
        if NaiveDateTime.compare(exp, NaiveDateTime.utc_now()) == :lt do
          {:error, :expired}
        else
          do_board_ticket(ticket)
        end
      ticket -> do_board_ticket(ticket)
    end
  end

  defp do_board_ticket(ticket) do
    ticket |> Ticket.board_changeset() |> Repo.update()
  end

  # ── Bus Checkpoints (live location reporting) ─────────────────────────────

  @doc """
  Resolves (creating if needed) the Trip for this checkpoint's
  (schedule, day) before inserting, so trip_id/organisation_id are always
  set from a real Trip rather than left for the caller to guess at.
  """
  def post_checkpoint(attrs) do
    schedule_id = Map.get(attrs, "schedule_id") || Map.get(attrs, :schedule_id)
    travel_date = Map.get(attrs, "travel_date") || Map.get(attrs, :travel_date)

    with {:ok, date} <- parse_date(travel_date),
         {:ok, trip} <- Trips.get_or_create_trip(schedule_id, date) do
      %BusCheckpoint{} |> BusCheckpoint.changeset(attrs, trip) |> Repo.insert()
    else
      _ ->
        %BusCheckpoint{}
        |> BusCheckpoint.changeset(attrs)
        |> Ecto.Changeset.add_error(:travel_date, "must be a valid date for an existing schedule")
        |> Ecto.Changeset.apply_action(:insert)
    end
  end

  defp parse_date(%Date{} = date), do: {:ok, date}
  defp parse_date(str) when is_binary(str), do: Date.from_iso8601(str)
  defp parse_date(_), do: :error

  def get_latest_checkpoint(schedule_id, %Date{} = date) do
    from(c in BusCheckpoint,
      where: c.schedule_id == ^schedule_id and c.travel_date == ^date,
      order_by: [desc: c.inserted_at],
      limit: 1,
      preload: [:reported_by]
    ) |> Repo.one()
  end

  def list_checkpoints(schedule_id, %Date{} = date) do
    from(c in BusCheckpoint,
      where: c.schedule_id == ^schedule_id and c.travel_date == ^date,
      order_by: [desc: c.inserted_at],
      preload: [:reported_by]
    ) |> Repo.all()
  end

  def track_by_booking_reference(ref) do
    booking =
      from(b in Booking,
        where: b.booking_reference == ^ref,
        preload: [schedule: [:route, :operator]]
      ) |> Repo.one()

    case booking do
      nil -> {:error, :not_found}
      b ->
        checkpoint = get_latest_checkpoint(b.schedule_id, b.travel_date)
        all_checkpoints = list_checkpoints(b.schedule_id, b.travel_date)
        {:ok, %{booking: b, checkpoint: checkpoint, history: all_checkpoints}}
    end
  end

  def change_checkpoint(%BusCheckpoint{} = cp, attrs \\ %{}) do
    BusCheckpoint.changeset(cp, attrs)
  end
end
