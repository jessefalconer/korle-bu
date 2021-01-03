class AddUnitWeightToItem < ActiveRecord::Migration[6.0]
  def change
    add_column :items, :unit_weight, :integer, default: 0, null: false
  end
end
