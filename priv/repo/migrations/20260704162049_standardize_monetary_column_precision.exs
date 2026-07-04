defmodule FleetMint.Repo.Migrations.StandardizeMonetaryColumnPrecision do
  use Ecto.Migration

  def change do
    alter table(:cashing_reports) do
      modify :expected_cashing, :decimal, precision: 12, scale: 2
      modify :received_cashing, :decimal, precision: 12, scale: 2
      modify :debt_balance, :decimal, precision: 12, scale: 2
      modify :expenditure, :decimal, precision: 12, scale: 2
    end

    alter table(:expenditures) do
      modify :amount, :decimal, precision: 12, scale: 2
    end

    alter table(:transactions) do
      modify :amount, :decimal, precision: 12, scale: 2
    end

    alter table(:fuel_logs) do
      modify :liters, :decimal, precision: 10, scale: 2
      modify :cost_per_liter, :decimal, precision: 10, scale: 2
      modify :total_cost, :decimal, precision: 12, scale: 2
    end

    alter table(:minibus_trips) do
      modify :fare_collected, :decimal, precision: 10, scale: 2
      modify :fuel_cost, :decimal, precision: 10, scale: 2
    end

    alter table(:vehicle_maintenances) do
      modify :cost, :decimal, precision: 12, scale: 2
    end
  end
end
