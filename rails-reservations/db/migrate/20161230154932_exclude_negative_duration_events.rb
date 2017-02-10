class ExcludeNegativeDurationEvents < ActiveRecord::Migration[5.0]
  def up
    execute("""
    ALTER TABLE events ADD CONSTRAINT positive_duration
    CHECK(end_date >= start_date);
    """)
  end

  def down
    execute("""
      ALTER TABLE events DROP CONSTRAINT positive_duration;
    """)
  end
end
