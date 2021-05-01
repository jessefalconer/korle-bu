class RemovePackagedQuantityFromItem < ActiveRecord::Migration[6.0]
  def change
    remove_column :items, :packaged_quantity, :integer
  end
end
