defmodule FleetMint.Ticketing do
  @moduledoc """
  The Ticketing context.
  
  This context handles operations related to ticket management, including
  creating, updating, and managing ticket status. It also provides functions
  for searching tickets, generating reports, and validating seat availability.
  """
  
  import Ecto.Query, warn: false
  alias FleetMint.Repo
  alias FleetMint.Ticketing.Ticket
  alias FleetMint.Transport.Fleet.Route
  
  @doc """
  Returns the list of tickets.
  
  ## Examples
  
      iex> list_tickets()
      [%Ticket{}, ...]
  
  """
  def list_tickets do
    Repo.all(Ticket)
    |> Repo.preload([:route, :bus, :user])
  end
  
  @doc """
  Gets a single ticket.
  
  Raises `Ecto.NoResultsError` if the Ticket does not exist.
  
  ## Examples
  
      iex> get_ticket!(123)
      %Ticket{}
      
      iex> get_ticket!(456)
      ** (Ecto.NoResultsError)
  
  """
  def get_ticket!(id) do 
    Repo.get!(Ticket, id)
    |> Repo.preload([:route, :bus, :user])
  end
  
  @doc """
  Gets a single ticket.
  
  Returns nil if the Ticket does not exist.
  
  ## Examples
  
      iex> get_ticket(123)
      %Ticket{}
      
      iex> get_ticket(456)
      nil
  
  """
  def get_ticket(id) do
    Repo.get(Ticket, id)
    |> case do
      nil -> nil
      ticket -> Repo.preload(ticket, [:route, :bus, :user])
    end
  end
  
  @doc """
  Gets a ticket by its ticket number.
  
  Returns nil if no ticket is found with the given ticket number.
  
  ## Examples
  
      iex> get_ticket_by_number("TKT-20250406-ABC123")
      %Ticket{}
      
      iex> get_ticket_by_number("NONEXISTENT")
      nil
  
  """
  def get_ticket_by_number(ticket_number) when is_binary(ticket_number) do
    Repo.get_by(Ticket, ticket_number: ticket_number)
    |> case do
      nil -> nil
      ticket -> Repo.preload(ticket, [:route, :bus, :user])
    end
  end
  
  @doc """
  Creates a ticket.
  
  ## Examples
  
      iex> create_ticket(%{field: value})
      {:ok, %Ticket{}}
      
      iex> create_ticket(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def create_ticket(attrs \\ %{}) do
    %Ticket{}
    |> Ticket.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, ticket} -> {:ok, Repo.preload(ticket, [:route, :bus, :user])}
      error -> error
    end
  end
  
  @doc """
  Updates a ticket.
  
  ## Examples
  
      iex> update_ticket(ticket, %{field: new_value})
      {:ok, %Ticket{}}
      
      iex> update_ticket(ticket, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def update_ticket(%Ticket{} = ticket, attrs) do
    ticket
    |> Ticket.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, ticket} -> {:ok, Repo.preload(ticket, [:route, :bus, :user])}
      error -> error
    end
  end
  
  @doc """
  Deletes a ticket.
  
  ## Examples
  
      iex> delete_ticket(ticket)
      {:ok, %Ticket{}}
      
      iex> delete_ticket(ticket)
      {:error, %Ecto.Changeset{}}
  
  """
  def delete_ticket(%Ticket{} = ticket) do
    Repo.delete(ticket)
  end
  
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ticket changes.
  
  ## Examples
  
      iex> change_ticket(ticket)
      %Ecto.Changeset{data: %Ticket{}}
  
  """
  def change_ticket(%Ticket{} = ticket, attrs \\ %{}) do
    Ticket.changeset(ticket, attrs)
  end
  
  @doc """
  Marks a ticket as used.
  
  ## Examples
  
      iex> mark_ticket_as_used(ticket)
      {:ok, %Ticket{}}
  
  """
  def mark_ticket_as_used(%Ticket{} = ticket) do
    update_ticket(ticket, %{status: "used"})
  end
  
  @doc """
  Cancels a ticket.
  
  ## Examples
  
      iex> cancel_ticket(ticket)
      {:ok, %Ticket{}}
  
  """
  def cancel_ticket(%Ticket{} = ticket) do
    update_ticket(ticket, %{status: "cancelled"})
  end
  
  @doc """
  Returns the list of tickets with a specific status.
  
  ## Examples
  
      iex> list_tickets_by_status("valid")
      [%Ticket{}, ...]
  
  """
  def list_tickets_by_status(status) when is_binary(status) do
    query = from t in Ticket,
            where: t.status == ^status,
            order_by: [desc: t.inserted_at]
    
    Repo.all(query)
    |> Repo.preload([:route, :bus, :user])
  end
  
  @doc """
  Returns the list of tickets for a specific travel date.
  
  ## Examples
  
      iex> list_tickets_by_travel_date(~D[2025-04-06])
      [%Ticket{}, ...]
  
  """
  def list_tickets_by_travel_date(date) do
    query = from t in Ticket,
            where: t.travel_date == ^date,
            order_by: [asc: t.departure_time]
    
    Repo.all(query)
    |> Repo.preload([:route, :bus, :user])
  end
  
  @doc """
  Returns the list of tickets for a date range.
  
  ## Examples
  
      iex> list_tickets_by_date_range(~D[2025-04-01], ~D[2025-04-07])
      [%Ticket{}, ...]
  
  """
  def list_tickets_by_date_range(start_date, end_date) do
    query = from t in Ticket,
            where: t.travel_date >= ^start_date and t.travel_date <= ^end_date,
            order_by: [asc: t.travel_date, asc: t.departure_time]
    
    Repo.all(query)
    |> Repo.preload([:route, :bus, :user])
  end
  
  @doc """
  Returns the list of tickets for a specific route.
  
  ## Examples
  
      iex> list_tickets_by_route(route_id)
      [%Ticket{}, ...]
  
  """
  def list_tickets_by_route(route_id) do
    query = from t in Ticket,
            where: t.route_id == ^route_id,
            order_by: [desc: t.travel_date, asc: t.departure_time]
    
    Repo.all(query)
    |> Repo.preload([:route, :bus, :user])
  end
  
  @doc """
  Returns the list of tickets for a specific bus.
  
  ## Examples
  
      iex> list_tickets_by_bus(bus_id)
      [%Ticket{}, ...]
  
  """
  def list_tickets_by_bus(bus_id) do
    query = from t in Ticket,
            where: t.bus_id == ^bus_id,
            order_by: [desc: t.travel_date, asc: t.departure_time]
    
    Repo.all(query)
    |> Repo.preload([:route, :bus, :user])
  end
  
  @doc """
  Returns the list of tickets issued by a specific user (cashier).
  
  ## Examples
  
      iex> list_tickets_by_user(user_id)
      [%Ticket{}, ...]
  
  """
  def list_tickets_by_user(user_id) do
    query = from t in Ticket,
            where: t.user_id == ^user_id,
            order_by: [desc: t.inserted_at]
    
    Repo.all(query)
    |> Repo.preload([:route, :bus, :user])
  end
  
  @doc """
  Returns the list of tickets for a specific passenger name.
  
  ## Examples
  
      iex> list_tickets_by_passenger_name("John Doe")
      [%Ticket{}, ...]
  
  """
  def list_tickets_by_passenger_name(name) when is_binary(name) do
    search_term = "%#{name}%"
    
    query = from t in Ticket,
            where: ilike(t.passenger_name, ^search_term),
            order_by: [desc: t.travel_date, asc: t.departure_time]
    
    Repo.all(query)
    |> Repo.preload([:route, :bus, :user])
  end
  
  @doc """
  Returns tickets for a specific bus on a specific date.
  
  Useful for checking seat availability and passenger manifests.
  
  ## Examples
  
      iex> list_tickets_by_bus_and_date(bus_id, ~D[2025-04-06])
      [%Ticket{}, ...]
  
  """
  def list_tickets_by_bus_and_date(bus_id, date) do
    query = from t in Ticket,
            where: t.bus_id == ^bus_id and t.travel_date == ^date and t.status != "cancelled",
            order_by: [asc: t.seat_number]
    
    Repo.all(query)
    |> Repo.preload([:route, :bus, :user])
  end
  
  @doc """
  Checks if a seat is available on a specific bus on a specific date.
  
  ## Examples
  
      iex> is_seat_available?(bus_id, ~D[2025-04-06], "A1")
      true
  
  """
  def is_seat_available?(bus_id, date, seat_number) do
    query = from t in Ticket,
            where: t.bus_id == ^bus_id and 
                   t.travel_date == ^date and 
                   t.seat_number == ^seat_number and 
                   t.status != "cancelled",
            select: count(t.id)
    
    Repo.one(query) == 0
  end
  
  @doc """
  Returns a list of all occupied seats for a bus on a specific date.
  
  ## Examples
  
      iex> list_occupied_seats(bus_id, ~D[2025-04-06])
      ["A1", "B3", "C5"]
  
  """
  def list_occupied_seats(bus_id, date) do
    query = from t in Ticket,
            where: t.bus_id == ^bus_id and t.travel_date == ^date and t.status != "cancelled",
            select: t.seat_number
    
    Repo.all(query)
  end
  
  @doc """
  Returns the total number of tickets sold for a specific date.
  
  ## Examples
  
      iex> count_tickets_by_date(~D[2025-04-06])
      42
  
  """
  def count_tickets_by_date(date) do
    query = from t in Ticket,
            where: t.travel_date == ^date and t.status != "cancelled",
            select: count(t.id)
    
    Repo.one(query) || 0
  end
  
  @doc """
  Calculates the total fare amount for tickets on a specific date.
  
  ## Examples
  
      iex> calculate_total_fare_by_date(~D[2025-04-06])
      #Decimal<1050.00>
  
  """
  def calculate_total_fare_by_date(date) do
    query = from t in Ticket,
            where: t.travel_date == ^date and t.status != "cancelled",
            select: sum(t.fare_amount)
    
    Repo.one(query) || Decimal.new("0.00")
  end
  
  @doc """
  Calculates the total fare amount for tickets in a date range.
  
  ## Examples
  
      iex> calculate_total_fare_by_date_range(~D[2025-04-01], ~D[2025-04-07])
      #Decimal<7350.00>
  
  """
  def calculate_total_fare_by_date_range(start_date, end_date) do
    query = from t in Ticket,
            where: t.travel_date >= ^start_date and t.travel_date <= ^end_date and t.status != "cancelled",
            select: sum(t.fare_amount)
    
    Repo.one(query) || Decimal.new("0.00")
  end
  
  @doc """
  Generates a daily sales report.
  
  ## Examples
  
      iex> generate_daily_sales_report(~D[2025-04-06])
      %{
        date: ~D[2025-04-06],
        total_tickets: 42,
        total_fare: #Decimal<1050.00>,
        tickets_by_route: [
          %{route_id: 1, route_name: "City Express", count: 15, amount: #Decimal<375.00>},
          %{route_id: 2, route_name: "Airport Shuttle", count: 27, amount: #Decimal<675.00>}
        ],
        tickets_by_status: [
          %{status: "valid", count: 30},
          %{status: "used", count: 10},
          %{status: "cancelled", count: 2}
        ]
      }
  
  """
  def generate_daily_sales_report(date) do
    # Total tickets and fare
    total_tickets = count_tickets_by_date(date)
    total_fare = calculate_total_fare_by_date(date)
    
    # Tickets by route
    tickets_by_route_query = from t in Ticket,
                             join: r in Route, on: t.route_id == r.id,
                             where: t.travel_date == ^date and t.status != "cancelled",
                             group_by: [t.route_id, r.name],
                             select: %{
                               route_id: t.route_id,
                               route_name: r.name,
                               count: count(t.id),
                               amount: sum(t.fare_amount)
                             }
    
    tickets_by_route = Repo.all(tickets_by_route_query) || []
    
    # Tickets by status
    tickets_by_status_query = from t in Ticket,
                              where: t.travel_date == ^date,
                              group_by: t.status,
                              select: %{
                                status: t.status,
                                count: count(t.id)
                              }
    
    tickets_by_status = Repo.all(tickets_by_status_query) || []
    
    # Construct and return the report
    %{
      date: date,
      total_tickets: total_tickets,
      total_fare: total_fare,
      tickets_by_route: tickets_by_route,
      tickets_by_status: tickets_by_status
    }
  end
end  # End of module FleetMint.Ticketing
