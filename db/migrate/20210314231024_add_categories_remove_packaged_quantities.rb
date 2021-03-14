class AddCategoriesRemovePackagedQuantities < ActiveRecord::Migration[6.0]
  def change
    add_reference :pallets, :category
    remove_column :items, :packaged_quantity, :integer
    add_column :pallets, :weight, :integer
    add_column :containers, :weight, :integer
  end
end
