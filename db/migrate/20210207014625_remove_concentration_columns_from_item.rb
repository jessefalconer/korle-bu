class RemoveConcentrationColumnsFromItem < ActiveRecord::Migration[6.0]
  def change
    remove_column :items, :concentration
    remove_column :items, :concentration_units
    remove_column :items, :concentration_description
  end
end
