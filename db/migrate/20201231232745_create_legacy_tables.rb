class CreateLegacyTables < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up do
        create_big_items
        create_item_boxes
        add_column :boxes, :number, :integer
        add_column :items, :category, :string
        add_column :pallets, :location, :string
        add_column :pallets, :description, :string
        add_column :containers, :destination, :string
      end

      dir.down do
        drop_table :big_items
        drop_table :item_boxes
      end
    end
  end

  def create_big_items
    create_table :big_items do |t|
      t.integer :weight
      t.string :description
      t.string :destination
      t.string :category
      t.text :notes

      t.belongs_to :container

      t.timestamps
    end
  end

  def create_item_boxes
    create_table :item_boxes do |t|
      t.integer :quantity, null: false, default: 0
      t.integer :weight
      t.datetime :item_expire

      t.belongs_to :box
      t.belongs_to :item

      t.timestamps
    end
  end
end
