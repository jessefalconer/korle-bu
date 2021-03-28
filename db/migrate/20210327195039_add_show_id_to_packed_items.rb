class AddShowIdToPackedItems < ActiveRecord::Migration[6.0]
  def change
    add_column :packed_items, :show_id, :boolean, default: false, null: false
    add_column :users, :masquerader, :boolean, default: false, null: false
  end
end
