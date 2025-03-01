class AddTimestampToUnpackingEvent < ActiveRecord::Migration[6.0]
  def change
    add_column :unpacking_events, :timestamp, :datetime, default: -> { "now()" }, null: false
  end
end
