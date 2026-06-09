defmodule FleetMint.Repo.Migrations.CreateFleetMintEcosystem do
  use Ecto.Migration

  def change do
    # Drop old basic tickets table (and dependent FKs) — replaced by QR-enabled tickets below
    execute "DROP TABLE IF EXISTS tickets CASCADE"

    # ─── FLEET: Core vehicles table ───────────────────────────────────────────
    create table(:vehicles) do
      add :registration_number, :string, null: false
      add :make, :string, null: false
      add :model, :string, null: false
      add :year, :integer
      add :color, :string
      add :vin, :string
      add :vehicle_type, :string, null: false, default: "bus"  # "bus" | "truck"
      add :status, :string, null: false, default: "active"
      add :current_driver_id, references(:users, on_delete: :nilify_all)
      add :description, :text
      timestamps()
    end

    create unique_index(:vehicles, [:registration_number])
    create index(:vehicles, [:vehicle_type])
    create index(:vehicles, [:status])

    # ─── FLEET: Bus extension table ───────────────────────────────────────────
    create table(:bus_profiles) do
      add :vehicle_id, references(:vehicles, on_delete: :delete_all), null: false
      add :seating_capacity, :integer, null: false, default: 0
      add :standing_capacity, :integer, default: 0
      add :amenities, {:array, :string}, default: []
      add :route_type, :string, default: "urban"  # urban | intercity | rural | express
      add :current_route_id, references(:routes, on_delete: :nilify_all)
      timestamps()
    end

    create unique_index(:bus_profiles, [:vehicle_id])

    # ─── FLEET: Truck extension table ─────────────────────────────────────────
    create table(:truck_profiles) do
      add :vehicle_id, references(:vehicles, on_delete: :delete_all), null: false
      add :payload_capacity_tons, :decimal, precision: 10, scale: 2
      add :cargo_volume_cbm, :decimal, precision: 10, scale: 2
      add :axle_configuration, :string
      add :truck_category, :string, default: "rigid"  # rigid | articulated | tipper | flatbed | tanker
      add :allowed_cargo_types, {:array, :string}, default: []
      add :refrigerated, :boolean, default: false
      add :gvw_kg, :integer
      timestamps()
    end

    create unique_index(:truck_profiles, [:vehicle_id])

    # ─── TRANSIT: Schedules ───────────────────────────────────────────────────
    create table(:schedules) do
      add :schedule_code, :string, null: false
      add :departure_time, :time, null: false
      add :estimated_arrival_time, :time
      add :days_of_week, {:array, :string}, default: []
      add :fare, :decimal, precision: 10, scale: 2, null: false
      add :available_seats, :integer, default: 0
      add :status, :string, default: "active"  # active | cancelled | suspended
      add :validation_mode, :string, default: "static"  # static | live
      add :vehicle_id, references(:vehicles, on_delete: :nilify_all)
      add :route_id, references(:routes, on_delete: :nilify_all)
      add :driver_id, references(:users, on_delete: :nilify_all)
      add :conductor_id, references(:users, on_delete: :nilify_all)
      add :notes, :text
      timestamps()
    end

    create unique_index(:schedules, [:schedule_code])
    create index(:schedules, [:route_id])
    create index(:schedules, [:vehicle_id])

    # ─── TRANSIT: Bookings ────────────────────────────────────────────────────
    create table(:bookings) do
      add :booking_reference, :string, null: false
      add :passenger_name, :string, null: false
      add :passenger_phone, :string
      add :passenger_email, :string
      add :seat_number, :string
      add :travel_date, :date, null: false
      add :status, :string, default: "confirmed"  # confirmed | cancelled | checked_in | no_show
      add :fare_paid, :decimal, precision: 10, scale: 2, null: false
      add :payment_method, :string, default: "cash"  # cash | airtel_money | card | bank_transfer
      add :payment_reference, :string
      add :booked_by_id, references(:users, on_delete: :nilify_all)
      add :schedule_id, references(:schedules, on_delete: :restrict), null: false
      add :notes, :text
      timestamps()
    end

    create unique_index(:bookings, [:booking_reference])
    create index(:bookings, [:travel_date])
    create index(:bookings, [:schedule_id])
    create index(:bookings, [:status])

    # ─── TRANSIT: QR Tickets ──────────────────────────────────────────────────
    create table(:tickets) do
      add :ticket_number, :string, null: false
      add :qr_payload, :text
      add :qr_svg, :text
      add :status, :string, default: "issued"  # issued | boarded | cancelled | expired
      add :boarded_at, :naive_datetime
      add :validation_token, :string
      add :expires_at, :naive_datetime
      add :booking_id, references(:bookings, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:tickets, [:ticket_number])
    create unique_index(:tickets, [:booking_id])

    # ─── FREIGHT: Clients ─────────────────────────────────────────────────────
    create table(:freight_clients) do
      add :company_name, :string, null: false
      add :contact_person, :string
      add :phone, :string
      add :email, :string
      add :address, :text
      add :city, :string
      add :client_type, :string, default: "general_business"
      add :tpin, :string
      add :credit_limit, :decimal, precision: 12, scale: 2, default: 0
      add :credit_balance, :decimal, precision: 12, scale: 2, default: 0
      add :status, :string, default: "active"  # active | suspended | blacklisted
      add :notes, :text
      timestamps()
    end

    create index(:freight_clients, [:status])
    create index(:freight_clients, [:client_type])

    # ─── FREIGHT: Trips (must come before orders for FK) ─────────────────────
    create table(:freight_trips) do
      add :trip_reference, :string, null: false
      add :origin, :string, null: false
      add :destination, :string, null: false
      add :planned_departure, :naive_datetime
      add :actual_departure, :naive_datetime
      add :planned_arrival, :naive_datetime
      add :actual_arrival, :naive_datetime
      add :status, :string, default: "scheduled"  # scheduled | loading | in_transit | delivered | cancelled
      add :current_location, :string
      add :odometer_start, :integer
      add :odometer_end, :integer
      add :fuel_used_liters, :decimal, precision: 8, scale: 2
      add :toll_fees, :decimal, precision: 10, scale: 2, default: 0
      add :other_expenses, :decimal, precision: 10, scale: 2, default: 0
      add :notes, :text
      add :vehicle_id, references(:vehicles, on_delete: :restrict), null: false
      add :driver_id, references(:users, on_delete: :nilify_all)
      add :co_driver_id, references(:users, on_delete: :nilify_all)
      add :created_by_id, references(:users, on_delete: :nilify_all)
      timestamps()
    end

    create unique_index(:freight_trips, [:trip_reference])
    create index(:freight_trips, [:vehicle_id])
    create index(:freight_trips, [:status])
    create index(:freight_trips, [:planned_departure])

    # ─── FREIGHT: Orders (after trips for FK) ────────────────────────────────
    create table(:freight_orders) do
      add :order_reference, :string, null: false
      add :cargo_type, :string, null: false
      add :cargo_description, :text
      add :weight_tons, :decimal, precision: 10, scale: 3
      add :volume_cbm, :decimal, precision: 10, scale: 2
      add :origin, :string, null: false
      add :destination, :string, null: false
      add :pickup_date, :date
      add :delivery_deadline, :date
      add :declared_value, :decimal, precision: 14, scale: 2
      add :agreed_rate, :decimal, precision: 10, scale: 2
      add :status, :string, default: "pending"  # pending | assigned | loading | in_transit | delivered | cancelled
      add :special_instructions, :text
      add :requires_refrigeration, :boolean, default: false
      add :hazmat_class, :string
      add :client_id, references(:freight_clients, on_delete: :restrict), null: false
      add :assigned_trip_id, references(:freight_trips, on_delete: :nilify_all)
      add :created_by_id, references(:users, on_delete: :nilify_all)
      timestamps()
    end

    create unique_index(:freight_orders, [:order_reference])
    create index(:freight_orders, [:client_id])
    create index(:freight_orders, [:status])
    create index(:freight_orders, [:pickup_date])

    # ─── FREIGHT: Trip Milestones ─────────────────────────────────────────────
    create table(:trip_milestones) do
      add :location, :string, null: false
      add :event_type, :string, null: false  # departed | checkpoint | fuel_stop | border_crossing | arrived | incident
      add :event_time, :naive_datetime, null: false
      add :latitude, :float
      add :longitude, :float
      add :odometer_reading, :integer
      add :notes, :string
      add :recorded_by, :string
      add :trip_id, references(:freight_trips, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:trip_milestones, [:trip_id])

    # ─── FREIGHT: Invoices ────────────────────────────────────────────────────
    create table(:freight_invoices) do
      add :invoice_number, :string, null: false
      add :invoice_date, :date, null: false
      add :due_date, :date
      add :base_amount, :decimal, precision: 12, scale: 2, null: false
      add :fuel_surcharge, :decimal, precision: 10, scale: 2, default: 0
      add :toll_surcharge, :decimal, precision: 10, scale: 2, default: 0
      add :vat_amount, :decimal, precision: 10, scale: 2, default: 0
      add :total_amount, :decimal, precision: 12, scale: 2, null: false
      add :status, :string, default: "draft"  # draft | issued | paid | overdue | cancelled
      add :payment_date, :date
      add :payment_reference, :string
      add :notes, :text
      add :client_id, references(:freight_clients, on_delete: :restrict), null: false
      add :trip_id, references(:freight_trips, on_delete: :restrict), null: false
      add :created_by_id, references(:users, on_delete: :nilify_all)
      timestamps()
    end

    create unique_index(:freight_invoices, [:invoice_number])
    create index(:freight_invoices, [:client_id])
    create index(:freight_invoices, [:status])
  end
end
