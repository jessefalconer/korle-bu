class AddColumnRoleToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :role, :string, default: "Volunteer", null: false
  end
end
