class RemoveCuidFromWarehouse < ActiveRecord::Migration[6.0]
  def change
    remove_column :warehouses, :custom_uid, :integer
  end
end
