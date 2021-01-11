class AddAreaToItem < ActiveRecord::Migration[6.0]
  def change
    add_column :items, :area_1, :float
    add_column :items, :area_2, :float
    add_column :items, :area_units, :string, limit: 255
    add_column :items, :area_description, :string, limit: 255

    add_column :items, :range_1, :float
    add_column :items, :range_2, :float
    add_column :items, :range_units, :string, limit: 255
    add_column :items, :range_description, :string, limit: 255

    add_column :items, :legacy_name, :string, limit: 255
  end
end
