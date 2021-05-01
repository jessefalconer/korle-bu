class AddCategoriesRemovePackagedQuantities < ActiveRecord::Migration[6.0]
  def change
    # packed_quantity removed in succeeding migration
    reversible do |dir|
      dir.up do
        remove_column :packed_items, :weight_units, :string
        remove_column :unpacking_events, :weight_units, :string
        add_reference :pallets, :category
        add_column :pallets, :weight, :float
        add_column :containers, :weight, :float

        change_column :boxes, :weight, :float
        change_column :items, :unit_weight, :float
        change_column :packed_items, :weight, :float
        change_column :packed_items, :remaining_weight, :float
        change_column :unpacking_events, :weight, :float
      end

      dir.down do
        add_column :packed_items, :weight_units, :string
        add_column :unpacking_events, :weight_units, :string
        remove_reference :pallets, :category
        remove_column :pallets, :weight, :float
        remove_column :containers, :weight, :float

        change_column :boxes, :weight, :integer
        change_column :items, :unit_weight, :integer
        change_column :packed_items, :weight, :integer
        change_column :packed_items, :remaining_weight, :integer
        change_column :unpacking_events, :weight, :integer
      end
    end
  end
end
