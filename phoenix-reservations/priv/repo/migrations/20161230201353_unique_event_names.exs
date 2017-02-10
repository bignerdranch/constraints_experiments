defmodule Reservations.Repo.Migrations.UniqueEventNames do
  use Ecto.Migration

  def change do
    create index(:events, [:name], unique: true)
  end
end
