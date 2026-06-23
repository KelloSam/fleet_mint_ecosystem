defmodule FleetMint.Repo.Migrations.AddUniqueSeatConstraintToBookings do
  use Ecto.Migration

  def change do
    create unique_index(
      :bookings,
      [:schedule_id, :travel_date, :seat_number],
      where: "status != 'cancelled' AND seat_number IS NOT NULL",
      name: :bookings_active_seat_unique
    )
  end
end
