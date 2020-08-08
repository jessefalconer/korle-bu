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
        create_boxed_items
        create_palletized_items
        create_containerized_items
      end

      dir.down do
        drop_table :boxes
        drop_table :pallets
        drop_table :containers
        drop_table :shipments
        drop_table :warehouses
        drop_table :items
        drop_table :boxed_items
        drop_table :palletized_items
        drop_table :containerized_items
      end
    end
  end

  def create_warehouses
    create_table :warehouses do |t|
      t.string :status
      t.string :notes
      t.string :name
      t.string :street
      t.string :postal_code
      t.string :city
      t.string :province
      t.string :country
      t.integer :identifier

      t.belongs_to :user

      t.timestamps
    end
  end

  def create_shipments
    create_table :shipments do |t|
      t.string :status
      t.string :notes
      t.string :name
      t.integer :custom_uid

      t.belongs_to :user
      t.references :receiving_warehouse, foreign_key: { to_table: :warehouses }, index: true
      t.references :shipping_warehouse, foreign_key: { to_table: :warehouses }, index: true

      t.timestamps
    end
  end

  def create_containers
    create_table :containers do |t|
      t.string :status
      t.string :notes
      t.string :name
      t.integer :custom_uid

      t.belongs_to :user
      t.belongs_to :shipment

      t.timestamps
    end
  end

  def create_pallets
    create_table :pallets do |t|
      t.string :status
      t.string :notes
      t.string :name
      t.integer :custom_uid

      t.belongs_to :user
      t.belongs_to :container

      t.timestamps
    end
  end

  def create_boxes
    create_table :boxes do |t|
      t.string :status
      t.string :notes
      t.string :name
      t.integer :custom_uid

      t.belongs_to :user
      t.belongs_to :container
      t.belongs_to :pallet

      t.timestamps
    end
  end

  def create_items
    create_table :items do |t|
      t.string :notes
      t.string :name
      t.string :category

      t.belongs_to :user

      t.timestamps
    end
  end

  def create_boxed_items
    create_table :boxed_items do |t|
      t.integer :quantity
      t.boolean :expires
      t.datetime :expiry_date
      t.integer :custom_uid

      t.belongs_to :box
      t.belongs_to :item
      t.belongs_to :user

      t.timestamps
    end
  end

  def create_palletized_items
    create_table :palletized_items do |t|
      t.integer :quantity
      t.boolean :expires
      t.datetime :expiry_date
      t.integer :custom_uid

      t.belongs_to :pallet
      t.belongs_to :item
      t.belongs_to :user

      t.timestamps
    end
  end

  def create_containerized_items
    create_table :containerized_items do |t|
      t.integer :quantity
      t.boolean :expires
      t.datetime :expiry_date
      t.integer :custom_uid

      t.belongs_to :container
      t.belongs_to :item
      t.belongs_to :user

      t.timestamps
    end
  end
end
