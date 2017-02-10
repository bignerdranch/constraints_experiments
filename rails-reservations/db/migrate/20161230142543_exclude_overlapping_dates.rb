class ExcludeOverlappingDates < ActiveRecord::Migration[5.0]
  def up
    execute("""
    CREATE EXTENSION IF NOT EXISTS btree_gist;
    ALTER TABLE events ADD CONSTRAINT no_overlaps
    EXCLUDE USING gist (
    daterange(\"start_date\", \"end_date\", '[]') WITH &&)
    DEFERRABLE INITIALLY IMMEDIATE;
    """)
  end

  def down
    execute("""
      ALTER TABLE events DROP CONSTRAINT no_overlaps;
    """)
  end

end
