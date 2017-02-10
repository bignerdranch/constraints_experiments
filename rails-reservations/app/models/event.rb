class Event < ApplicationRecord

  validates :name, :start_date, :end_date, presence: true
  validates :name, uniqueness: true

  validate :positive_duration, if: :has_date_range?
  validate :no_overlapping_events, if: :has_date_range?

  scope :overlapping, -> (start_date, end_date) {
    where(
      "start_date <= :end_date AND :start_date <= end_date",
      start_date: start_date, end_date: end_date
    )
  }

  def positive_duration
    unless end_date >= start_date
      errors.add(:end_date, "must be on or after start date")
    end
  end

  def no_overlapping_events
    overlaps = Event.overlapping(start_date, end_date)
    overlaps = overlaps.where("id != ?", id) if id.present?
    if overlaps.any?
      dates = overlaps.map {|e|
        [e.start_date, e.end_date].join(" to ")
      }.join(", ")
      errors.add(:base, "must not overlap existing events. Overlaps: #{dates}")
    end
  end

  def has_date_range?
    start_date.present? && end_date.present?
  end

  # like a normal save, but also returns false if a constraint failed
  def save_with_constraints(validate: true)
    save(validate: validate)
  rescue ValidationRaceCondition
    Rails.logger.info "validations missed something due to a race condition - validate again!"
    # re-run validations to set a user-friendly error mesage for whatever the
    # validation missed the first time but the constraints caught
    valid?
    false
  end

  # Rescuing this will catch constraint errors that indicate that, due to a
  # race condition, one of our validations did not do its job.
  # Eg, two users tried to claim the same event name at the same time, both got
  # through the validations, but the database unique constraint stopped the
  # second one.
  # See http://blog.honeybadger.io/level-up-ruby-rescue-with-dynamic-exception-matchers/
  class ValidationRaceCondition
    # returns true if this is something we should rescue
    def self.===(exception)
      return true if exception.is_a?(ActiveRecord::RecordNotUnique) && exception.cause.message.match('unique constraint "index_events_on_name"')
      return true if exception.cause.is_a?(PG::ExclusionViolation) && exception.message.match("no_overlaps")
      false
    end
  end

end
