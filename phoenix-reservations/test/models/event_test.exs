defmodule Reservations.EventTest do
  use Reservations.ModelCase

  alias Reservations.Event

  @valid_attrs %{end_date: %{day: 17, month: 4, year: 2010}, name: "some content", start_date: %{day: 17, month: 4, year: 2010}}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Event.changeset(%Event{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Event.changeset(%Event{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "requires positive duration" do
    negative_one_days = Event.changeset(
      %Event{}, %{
        name: "Some Event",
        start_date: %{year: 2016, month: 6, day: 15},
        end_date:   %{year: 2016, month: 6, day: 14},
      }
    )
    assert match? [base: {_message, [validation: :validate_positive_duration]}], negative_one_days.errors

    single_day = Event.changeset(
      %Event{}, %{
        name: "Some Event",
        start_date: %{year: 2016, month: 6, day: 14},
        end_date:   %{year: 2016, month: 6, day: 14},
      }
    )
    refute match? [base: {_message, [validation: :validate_positive_duration]}], single_day.errors

    two_days = Event.changeset(
      %Event{}, %{
        name: "Some Event",
        start_date: %{year: 2016, month: 6, day: 14},
        end_date:   %{year: 2016, month: 6, day: 15},
      }
    )
    refute match? [base: {_message, [validation: :validate_positive_duration]}], two_days.errors
  end

  describe "requiring a unique name" do

    test "checks for it in the validation phase" do
      first = Event.changeset(
        %Event{}, %{
          name: "Summer Bash 2016",
          start_date: %{year: 2016, month: 6, day: 14},
          end_date:   %{year: 2016, month: 6, day: 15},
        }
      )
      first |> Repo.insert!

      second = Event.cast_params(
        %Event{}, %{
          name: "Summer Bash 2016",
          start_date: %{year: 2016, month: 7, day: 14},
          end_date:   %{year: 2016, month: 7, day: 15},
        }
      ) |> Event.run_validations
      assert match? [name: {_message, [validation: [:validate_unique_unreliably, [:name]]]}], second.errors

      second = Event.cast_params(
        %Event{}, %{
          name: "Some Other Event Name",
          start_date: %{year: 2016, month: 7, day: 14},
          end_date:   %{year: 2016, month: 7, day: 15},
        }
      ) |> Event.run_validations
      refute match? [name: {_message, [validation: [:validate_unique_unreliably, [:name]]]}], second.errors
    end

    test "doesn't blow up if the changeset being validated has no name" do
      first = Event.changeset(
        %Event{}, %{
          name: "Summer Bash 2016",
          start_date: %{year: 2016, month: 6, day: 14},
          end_date:   %{year: 2016, month: 6, day: 15},
        }
      )
      first |> Repo.insert!

      second = Event.cast_params(
        %Event{}, %{
          start_date: %{year: 2016, month: 7, day: 14},
          end_date:   %{year: 2016, month: 7, day: 15},
        }
      ) |> Event.run_validations
      refute match? [name: {_message, [validation: :validate_unique_name]}], second.errors
    end

    test "ignores the original event when looking for duplicate names" do
      first = Event.changeset(
        %Event{}, %{
          name: "Summer Bash 2016",
          start_date: %{year: 2016, month: 6, day: 14},
          end_date:   %{year: 2016, month: 6, day: 15},
        }
      )
      first = first |> Repo.insert!

      update = Event.cast_params(
        first,
        %{
          name: "Summer Bash 2016",
          end_date: %{year: 2016, month: 6, day: 16}
        }
      ) |> Event.run_validations
      refute match? {_message, [validation: :validate_unique_name]}, Keyword.get(update.errors, :name)
    end

    test "in case of race conditions, catches the constraint error" do
      first = Event.changeset(
        %Event{}, %{
          name: "Summer Bash 2016",
          start_date: %{year: 2016, month: 6, day: 14},
          end_date:   %{year: 2016, month: 6, day: 15},
        }
      )
      first |> Repo.insert!

      second = Event.cast_params(
        %Event{}, %{
          name: "Summer Bash 2016",
          start_date: %{year: 2016, month: 7, day: 14},
          end_date:   %{year: 2016, month: 7, day: 15},
        }
      ) |> Event.prepare_for_constraints
      {:error, attempted_insert} = Repo.insert(second)
      assert match? [name: {"has already been taken", _}], attempted_insert.errors
    end
  end

  describe "disallowing overlapping dates" do

    test "checks for them in the validation phase" do
      first = Event.changeset(
        %Event{}, %{
          name: "Summer Bash 2016",
          start_date: %{year: 2016, month: 6, day: 14},
          end_date:   %{year: 2016, month: 6, day: 15},
        }
      )
      first |> Repo.insert!

      Enum.each([{13, 14}, {14, 15}, {15, 16}], fn ({start_day, end_day}) ->
        second = Event.cast_params(
         %Event{}, %{
           name: "Water Balloon Mania 2016-06-#{start_day}",
           start_date: %{year: 2016, month: 6, day: start_day},
           end_date:   %{year: 2016, month: 6, day: end_day},
         }
        ) |> Event.run_validations
      assert match? [base: {_message, [validation: :validate_no_overlapping_dates]}], second.errors
      end)

      Enum.each([{12, 13}, {16, 17}], fn ({start_day, end_day}) ->
        second = Event.cast_params(
         %Event{}, %{
           name: "Water Balloon Mania 2016-06-#{start_day}",
           start_date: %{year: 2016, month: 6, day: start_day},
           end_date:   %{year: 2016, month: 6, day: end_day},
         }
        ) |> Event.run_validations
      refute match? [base: {_message, [validation: :validate_no_overlapping_dates]}], second.errors
      end)
    end

    test "doesn't blow up if the changeset being validated is missing one or more dates" do
      first = Event.changeset(
        %Event{}, %{
          name: "Summer Bash 2016",
          start_date: %{year: 2016, month: 6, day: 14},
          end_date:   %{year: 2016, month: 6, day: 15},
        }
      )
      first |> Repo.insert!

      second = Event.cast_params(
       %Event{}, %{
         name: "Water Balloon Mania 2016",
       }
      ) |> Event.run_validations
      refute match? [base: {_message, [validation: :validate_no_overlaps]}], second.errors
    end

    test "ignores the original event when looking for overlaps" do
      first = Event.changeset(
        %Event{}, %{
          name: "Summer Bash 2016",
          start_date: %{year: 2016, month: 6, day: 14},
          end_date:   %{year: 2016, month: 6, day: 15},
        }
      )
      first = first |> Repo.insert!

      update = Event.cast_params(
        first,
        %{
          start_date: %{year: 2016, month: 6, day: 14},
          end_date:   %{year: 2016, month: 6, day: 15},
        }
      ) |> Event.run_validations
      refute match? {_message, [validation: :validate_no_overlaps]}, Keyword.get(update.errors, :base)
    end


    test "in case of race conditions, catches the constraint error" do
      first = Event.changeset(
        %Event{}, %{
          name: "Summer Bash 2016",
          start_date: %{year: 2016, month: 6, day: 14},
          end_date:   %{year: 2016, month: 6, day: 15},
        }
      )
      first |> Repo.insert!

      Enum.each([{13, 14}, {14, 15}, {15, 16}], fn ({start_day, end_day}) ->
        second = Event.cast_params(
         %Event{}, %{
           name: "Water Balloon Mania 2016-06-#{start_day}",
           start_date: %{year: 2016, month: 6, day: start_day},
           end_date:   %{year: 2016, month: 6, day: end_day},
         }
        ) |> Event.prepare_for_constraints
        {:error, attempted_insert} = Repo.insert(second)
        assert match? [base: {"cannot overlap dates with another event", []}], attempted_insert.errors
      end)

      Enum.each([{12, 13}, {16, 17}], fn ({start_day, end_day}) ->
        second = Event.cast_params(
         %Event{}, %{
           name: "Water Balloon Mania 2016-06-#{start_day}",
           start_date: %{year: 2016, month: 6, day: start_day},
           end_date:   %{year: 2016, month: 6, day: end_day},
         }
        ) |> Event.prepare_for_constraints
        {:ok, attempted_insert} = Repo.insert(second)
        # TODO - better way to assert absence of this specific error?
        assert_raise KeyError, fn -> attempted_insert.errors end
      end)
    end

  end

end
