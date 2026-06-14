defmodule FleetMint.Repo.Migrations.CreateComplaints do
  use Ecto.Migration

  def change do
    create table(:complaints) do
      add :type, :string, null: false, default: "complaint"
      add :category, :string, null: false, default: "bus_service"
      add :passenger_name, :string, null: false
      add :passenger_phone, :string
      add :booking_reference, :string
      add :staff_member_name, :string
      add :subject, :string
      add :description, :text, null: false
      add :status, :string, null: false, default: "pending"
      add :resolution_notes, :text
      add :reviewed_by_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:complaints, [:status])
    create index(:complaints, [:type])
    create index(:complaints, [:booking_reference])
  end
end
