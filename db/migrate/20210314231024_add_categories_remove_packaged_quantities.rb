class AddCategoriesRemovePackagedQuantities < ActiveRecord::Migration[6.0]
  def change
    # packed_quantity removed in succeeding migration
    remove_column :packed_items, :weight_units, :string
    remove_column :unpacking_events, :weight_units, :string
    add_reference :pallets, :category
    add_column :pallets, :weight, :integer
    add_column :containers, :weight, :integer
  end
end
