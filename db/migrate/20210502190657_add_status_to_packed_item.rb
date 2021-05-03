class AddStatusToPackedItem < ActiveRecord::Migration[6.0]
  def change
    add_column :packed_items, :status, :string
  end
end
