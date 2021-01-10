class CreateUnpackingEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :unpacking_events do |t|
      t.integer :quantity, null: false, default: 0
      t.integer :weight
      t.string :weight_units
      t.string :notes, limit: 255

      t.belongs_to :packed_item
      t.belongs_to :user

      t.timestamps
    end

    add_column :packed_items, :remaining_quantity, :integer, default: 0, null: false
    add_column :packed_items, :remaining_weight, :integer, default: 0, null: false
  end
end
