class RemoveRemainingWeightFromPackedItem < ActiveRecord::Migration[6.0]
  def change
    remove_column :packed_items, :remaining_weight, :float
  end
end
