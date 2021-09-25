class AddPointOfContactToHospital < ActiveRecord::Migration[6.0]
  def change
    add_column :hospitals, :point_of_contact_name, :string
    add_column :hospitals, :point_of_contact_phone, :string
  end
end
