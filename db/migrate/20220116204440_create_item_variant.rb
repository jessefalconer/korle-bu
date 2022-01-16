class CreateItemVariant < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up do
        create_item_variants

        add_reference :packed_items, :item_variant

        remove_column :items, :object, :string
        remove_column :items, :brand, :string
        remove_column :items, :keywords, :string
        remove_column :items, :category, :string
        remove_column :items, :standardized_size, :string
        remove_column :items, :numerical_size_1, :float
        remove_column :items, :numerical_size_2, :float
        remove_column :items, :numerical_units_1, :string
        remove_column :items, :numerical_units_2, :string
        remove_column :items, :numerical_description_1, :string
        remove_column :items, :numerical_description_2, :string
        remove_column :items, :generated_name_with_keywords, :string
        remove_column :items, :unit_weight, :float
        remove_column :items, :area_units, :string
        remove_column :items, :area_1, :float
        remove_column :items, :area_2, :float
        remove_column :items, :area_description, :string
        remove_column :items, :range_units, :string
        remove_column :items, :range_1, :float
        remove_column :items, :range_2, :float
        remove_column :items, :range_description, :string
        remove_column :items, :legacy_name, :string

        # obsolete on production
        drop_table :item_boxes
        drop_table :big_items
      end

      dir.down do
        # obsolete on production
        create_table :item_boxes
        create_table :big_items

        add_column :items, :object, :string, limit: 255
        add_column :items, :brand, :string, limit: 255
        add_column :items, :keywords, :string
        add_column :items, :category, :string
        add_column :items, :standardized_size, :string, limit: 255
        add_column :items, :numerical_size_1, :float
        add_column :items, :numerical_size_2, :float
        add_column :items, :numerical_units_1, :string, limit: 255
        add_column :items, :numerical_units_2, :string, limit: 255
        add_column :items, :numerical_description_1, :string, limit: 255
        add_column :items, :numerical_description_2, :string, limit: 255
        add_column :items, :generated_name_with_keywords, :string
        add_column :items, :unit_weight, :float, default: 0.0, null: false
        add_column :items, :area_units, :string, limit: 255
        add_column :items, :area_1, :float
        add_column :items, :area_2, :float
        add_column :items, :area_description, :string, limit: 255
        add_column :items, :range_units, :string, limit: 255
        add_column :items, :range_1, :float
        add_column :items, :range_2, :float
        add_column :items, :range_description, :string, limit: 255
        add_column :items, :legacy_name, :string

        remove_reference :packed_items, :item_variant

        drop_table :item_variants
      end
    end
  end

  def create_item_variants
    create_table :item_variants do |t|
      t.string :name, limit: 255
      t.boolean :verified, default: false, null: false

      t.belongs_to :item
      t.belongs_to :user

      t.timestamps
    end
  end
end
