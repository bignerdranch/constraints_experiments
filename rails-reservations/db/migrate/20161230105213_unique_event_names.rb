class UniqueEventNames < ActiveRecord::Migration[5.0]
  def change
    add_index :events, :name, unique: true
  end
end
