class DisableNullConstraints < ActiveRecord::Migration[6.0]
  def change
    change_column_null :pallets, :status, true
    change_column_null :containers, :status, true
  end
end
