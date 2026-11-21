# frozen_string_literal: true

# Serial numbers ("S/N") get their own field instead of being typed into the
# brand or name.
class AddSerialNumberToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :serial_number, :string
  end
end
