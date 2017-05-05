defmodule Reservations.Event do
  use Reservations.Web, :model
  alias Reservations.Event
  alias Reservations.Repo

  schema "events" do
    field :name, :string
    field :start_date, Ecto.Date
    field :end_date, Ecto.Date

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast_params(params)
    # I split these like this to make it easy to test constraints and
    # validations separately, or just comment out `run_validations`
    |> run_validations
    |> prepare_for_constraints
  end

  def cast_params(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :start_date, :end_date])
  end

  def run_validations(struct) do
    struct
    |> validate_in_memory
    |> unsafe_validate_against_repo
  end

  def validate_in_memory(struct) do
    struct
    |> validate_required([:name, :start_date, :end_date])
    |> validate_positive_duration
  end

  # These validations are "unsafe" because they can't prevent race conditions;
  # we must also have constraints to reliably prevent conflicting data.
  # But in most cases, these will enable a user to fix conflicting data at the
  # same time that they correct (eg) blank fields.
  def unsafe_validate_against_repo(struct) do
    struct
    |> validate_unique_unreliably([:name], Repo, :name, "must provide a unique value")
    |> validate_no_overlapping_dates()
  end

  def prepare_for_constraints(struct) do
    struct
    |> unique_constraint(:name)
    |> exclusion_constraint(:base, name: :no_overlaps, message: "cannot overlap dates with another event")
  end

  def validate_positive_duration(changeset) do
    if get_field(changeset, :start_date) <= get_field(changeset, :end_date) do
      changeset
    else
      add_error(
      changeset,
      :base,
      "start date cannot be before end date",
      [validation: :validate_positive_duration]
      )
    end
  end

  def validate_unique_unreliably(changeset, field_names, repo, error_field, error_message \\ "must be unique") do
    where_clause = Enum.map(field_names, fn (field_name) ->
      {field_name, get_field(changeset, field_name)}
    end)

    if Enum.any?(where_clause, fn (tuple) -> is_nil(elem(tuple, 1)) end) do
      changeset
    else
      dups_query = Ecto.Query.from q in __MODULE__, where: ^where_clause

      # For updates, don't flag record as a dup of itself
      changeset_id = get_field(changeset, :id)
      dups_query = if is_nil(changeset_id) do
        dups_query
      else
        from q in dups_query, where: q.id != ^changeset_id
      end

      dups_exists_query = from q in dups_query, select: true, limit: 1
      case repo.one(dups_exists_query) do
        true -> add_error(
          changeset,
          error_field,
          error_message,
          [validation: [:validate_unique_unreliably, field_names]]
        )
        nil  -> changeset
      end
    end
  end

  defp validate_no_conflicting_names(changeset = %Ecto.Changeset{changes: %{name: name}}) when not is_nil(name) do
    dups_query = from e in Event, where: e.name == ^name
    # For updates, don't flag event as a dup of itself
    id = get_field(changeset, :id)
    dups_query = if is_nil(id) do
      dups_query
    else
      from e in dups_query, where: e.id != ^id
    end

    exists_query = from q in dups_query, select: true, limit: 1
    case Repo.one(exists_query) do
      true -> add_error(
        changeset, :name, "has already been taken", [validation: :validate_no_conflicting_names]
      )
      nil  -> changeset
    end
  end

  # If event has no name or a nil name, it isn't a conflict
  defp validate_no_conflicting_names(changeset), do: changeset

  defp validate_no_overlapping_dates(changeset = %Ecto.Changeset{changes: %{start_date: start_date, end_date: end_date}}) when not is_nil(start_date) and not is_nil(end_date) do

    overlap_query = Event
    |> Reservations.Event.Scopes.overlapping(start_date, end_date)

    # For updates, don't flag event as overlapping itself
    id = get_field(changeset, :id)
    overlap_query = if is_nil(id) do
      overlap_query
    else
      from e in overlap_query, where: e.id != ^id
    end

    exists_query = from q in overlap_query, select: true, limit: 1
    case Repo.one(exists_query) do
      true -> add_error(
        changeset, :base, "may not overlap another event", [validation: :validate_no_overlapping_dates]
      )
      nil  -> changeset
    end
  end

  # if start date or end date is missing or nil, it isn't an overlap
  defp validate_no_overlapping_dates(changeset), do: changeset
end
