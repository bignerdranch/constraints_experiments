defmodule Reservations.Repo.Migrations.PostitiveDuration do
  use Ecto.Migration

  def change do
    create constraint(
      :events, :positive_duration, check: "start_date <= end_date"
    )
  end
end
