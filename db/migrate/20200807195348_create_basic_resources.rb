class CreateBasicResources < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up do
        create_warehouses
        create_shipments
        create_containers
        create_pallets
        create_boxes
        create_items
        create_categories
        create_packed_items
      end

      dir.down do
        drop_table :boxes
        drop_table :pallets
        drop_table :containers
        drop_table :shipments
        drop_table :warehouses
        drop_table :categories
        drop_table :items
        drop_table :packed_items
      end
    end
  end

  def create_warehouses
    create_table :warehouses do |t|
      t.string :status, null: false, default: "Active"
      t.string :description, limit: 255
      t.string :name, limit: 255
      t.string :street, limit: 255
      t.string :postal_code, limit: 255
      t.string :city, limit: 255
      t.string :province, limit: 255
      t.string :country, limit: 255
      t.integer :custom_uid

      t.belongs_to :user

      t.timestamps
    end
  end

  def create_shipments
    create_table :shipments do |t|
      t.string :name, limit: 255
      t.string :status, default: "In Progress", null: false
      t.text :notes
      t.integer :custom_uid

      t.belongs_to :user
      t.references :receiving_warehouse, foreign_key: { to_table: :warehouses }, index: true
      t.references :shipping_warehouse, foreign_key: { to_table: :warehouses }, index: true

      t.timestamps
    end
  end

  def create_containers
    create_table :containers do |t|
      t.string :name, limit: 255
      t.string :status, default: "In Progress", null: false
      t.string :notes, limit: 255
      t.integer :custom_uid

      t.belongs_to :user
      t.belongs_to :shipment

      t.timestamps
    end
  end

  def create_pallets
    create_table :pallets do |t|
      t.string :name, limit: 255
      t.string :status, default: "In Progress", null: false
      t.string :notes, limit: 255
      t.integer :custom_uid

      t.belongs_to :user
      t.belongs_to :container

      t.timestamps
    end
  end

  def create_boxes
    create_table :boxes do |t|
      t.string :name, limit: 255
      t.string :status, default: "In Progress", null: false
      t.string :notes, limit: 255
      t.integer :custom_uid
      t.integer :weight

      t.belongs_to :user
      t.belongs_to :pallet
      t.belongs_to :container

      t.timestamps
    end
  end

  def create_items
    create_table :items do |t|
      t.string :object, limit: 255
      t.string :brand, limit: 255

      t.string :standardized_size, limit: 255

      t.float :concentration
      t.string :concentration_units, limit: 255
      t.string :concentration_description, limit: 255


      t.float :numerical_size_1
      t.string :numerical_units_1, limit: 255
      t.string :numerical_description_1, limit: 255

      t.float :numerical_size_2
      t.string :numerical_units_2, limit: 255
      t.string :numerical_description_2, limit: 255

      t.integer :packaged_quantity

      t.string :generated_name
      t.string :generated_name_with_keywords
      t.string :notes, limit: 255
      t.string :keywords, limit: 255
      t.boolean :verified, null: false, default: false
      t.boolean :flagged, null: false, default: false

      t.belongs_to :user
      t.belongs_to :category, index: true

      t.timestamps
    end
  end

  def create_categories
    create_table :categories do |t|
      t.string :name, limit: 255
      t.string :description, limit: 255

      t.belongs_to :user

      t.timestamps
    end
  end

  def create_packed_items
    create_table :packed_items do |t|
      t.integer :quantity, null: false, default: 0
      t.integer :weight
      t.string :weight_units
      t.datetime :expiry_date

      t.belongs_to :box, index: true
      t.belongs_to :pallet, index: true
      t.belongs_to :container, index: true
      t.belongs_to :shipment, index: true
      t.belongs_to :item, index: true
      t.belongs_to :user, index: true

      t.timestamps
    end
  end
end
