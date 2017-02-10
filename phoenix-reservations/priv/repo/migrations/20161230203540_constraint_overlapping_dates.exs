defmodule Reservations.Repo.Migrations.ConstraintOverlappingDates do
  use Ecto.Migration

  def change do
    create constraint(
      :events,
      :no_overlaps,
      exclude: ~s|gist (daterange("start_date", "end_date", '[]') WITH &&) DEFERRABLE INITIALLY IMMEDIATE|
    )
  end
end
