defmodule Reservations.Event.Scopes do
  import Ecto
  import Ecto.Query

  def overlapping(query, start_date, end_date) do
    from event in query,
    where: event.start_date <= ^end_date and ^start_date <= event.end_date
  end
end

