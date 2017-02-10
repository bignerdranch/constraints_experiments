require 'test_helper'

class EventTest < ActiveSupport::TestCase
  test "overlap scope finds overlaps" do
    existing = Event.create(
      name: "Summer Banquet 2016", start_date: "2016-06-15", end_date: "2016-06-16"
    )
    # doesn't overlap if we search before or after the event
    assert_equal [], Event.overlapping("2016-06-13", "2016-06-14")
    assert_equal [], Event.overlapping("2016-06-17", "2016-06-18")

    # overlaps if the dates are the same
    assert_equal [existing], Event.overlapping("2016-06-15", "2016-06-16")
    # overlaps if it touches one end or the other
    assert_equal [existing], Event.overlapping("2016-06-14", "2016-06-15")
    assert_equal [existing], Event.overlapping("2016-06-16", "2016-06-17")
    # overlaps if it includes the event entirely
    assert_equal [existing], Event.overlapping("2016-06-14", "2016-06-17")
  end

  test "validates non-overlap with existing events" do
    [1, 3, 5].each do |n|
      Event.create!(
        name: "Summer Event #{n}",
        start_date: Date.new(2016, 6, n),
        end_date: Date.new(2016, 6, n + 1),
      )
    end
    overlapping = Event.new(
      name: "Summer Fling", start_date: "2016-06-03", end_date: "2016-06-07"
    )
    overlapping.valid?
    assert overlapping.errors[:base].include?(
      "must not overlap existing events. Overlaps: 2016-06-03 to 2016-06-04, 2016-06-05 to 2016-06-06"
    )
    future = Event.new(
      name: "Winter Bash", start_date: "2017-02-03", end_date: "2017-02-08"
    )
    future.valid?
    refute future.errors[:base].detect {|m| m.match("must not overlap")}
  end
end
