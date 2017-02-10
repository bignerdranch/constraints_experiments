defmodule Reservations.Repo.Migrations.CreateEvent do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :name, :string
      add :start_date, :date
      add :end_date, :date

      timestamps()
    end

  end
end
