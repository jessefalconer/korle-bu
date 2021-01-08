class AddWarehouseToUser < ActiveRecord::Migration[6.0]
  def change
    add_reference :users, :warehouse
  end
end
