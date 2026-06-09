defmodule FleetMint.Repo.Migrations.AlignSchemasWithDb do
  use Ecto.Migration

  def up do
    # ── Users ────────────────────────────────────────────────────────────────
    alter table(:users) do
      add :username, :string
      add :password_hash, :string
      add :full_name, :string
      add :active, :boolean, default: false, null: false
      add :last_login, :naive_datetime
    end

    # Backfill username from existing name column so unique constraint can apply
    execute "UPDATE users SET username = COALESCE(name, 'user_' || id::text), full_name = name WHERE username IS NULL"
    execute "ALTER TABLE users ALTER COLUMN username SET NOT NULL"

    create unique_index(:users, [:username])

    # ── Buses ─────────────────────────────────────────────────────────────────
    # Rename number → registration_number
    drop_if_exists index(:buses, [:number])
    rename table(:buses), :number, to: :registration_number

    alter table(:buses) do
      add :model, :string
      add :year, :integer
      add :status, :string, default: "active"
      add :description, :text
    end

    execute "UPDATE buses SET status = 'active' WHERE status IS NULL"

    create unique_index(:buses, [:registration_number])

    # ── Routes ────────────────────────────────────────────────────────────────
    # Rename start_point/end_point → start_location/end_location
    drop_if_exists index(:routes, [:start_point])
    drop_if_exists index(:routes, [:end_point])

    rename table(:routes), :start_point, to: :start_location
    rename table(:routes), :end_point, to: :end_location

    alter table(:routes) do
      add :distance, :decimal, precision: 10, scale: 2
      add :duration, :integer
      add :fare, :decimal, precision: 10, scale: 2
      add :status, :string, default: "active"
      add :description, :text
    end

    execute "UPDATE routes SET status = 'active' WHERE status IS NULL"

    create index(:routes, [:start_location])
    create index(:routes, [:end_location])

    # ── Transactions ──────────────────────────────────────────────────────────
    # Rename type → payment_method
    drop_if_exists index(:transactions, [:user_id, :type])
    rename table(:transactions), :type, to: :payment_method

    alter table(:transactions) do
      add :status, :string, default: "success"
      add :reference_number, :string
      add :transaction_date, :utc_datetime
      add :payment_details, :map
    end

    execute "UPDATE transactions SET status = 'success', transaction_date = inserted_at WHERE status IS NULL"

    create unique_index(:transactions, [:reference_number], where: "reference_number IS NOT NULL")
    create index(:transactions, [:user_id, :payment_method])

    # ── Cashing Reports ───────────────────────────────────────────────────────
    # Add bus and conductor linkage so every cashing record is tied to a bus/driver
    alter table(:cashing_reports) do
      add :bus_id, references(:buses, on_delete: :restrict)
      add :conductor_id, references(:users, on_delete: :restrict)
      add :report_date, :date
    end

    create index(:cashing_reports, [:bus_id])
    create index(:cashing_reports, [:conductor_id])
    create index(:cashing_reports, [:report_date])
  end

  def down do
    # cashing_reports
    drop_if_exists index(:cashing_reports, [:report_date])
    drop_if_exists index(:cashing_reports, [:conductor_id])
    drop_if_exists index(:cashing_reports, [:bus_id])
    alter table(:cashing_reports) do
      remove :report_date
      remove :conductor_id
      remove :bus_id
    end

    # transactions
    drop_if_exists index(:transactions, [:reference_number])
    drop_if_exists index(:transactions, [:user_id, :payment_method])
    alter table(:transactions) do
      remove :payment_details
      remove :transaction_date
      remove :reference_number
      remove :status
    end
    rename table(:transactions), :payment_method, to: :type
    create index(:transactions, [:user_id, :type])

    # routes
    drop_if_exists index(:routes, [:end_location])
    drop_if_exists index(:routes, [:start_location])
    alter table(:routes) do
      remove :description
      remove :status
      remove :fare
      remove :duration
      remove :distance
    end
    rename table(:routes), :start_location, to: :start_point
    rename table(:routes), :end_location, to: :end_point
    create index(:routes, [:start_point])
    create index(:routes, [:end_point])

    # buses
    drop_if_exists index(:buses, [:registration_number])
    alter table(:buses) do
      remove :description
      remove :status
      remove :year
      remove :model
    end
    rename table(:buses), :registration_number, to: :number
    create unique_index(:buses, [:number])

    # users
    drop_if_exists index(:users, [:username])
    alter table(:users) do
      remove :last_login
      remove :active
      remove :full_name
      remove :password_hash
      remove :username
    end
  end
end
