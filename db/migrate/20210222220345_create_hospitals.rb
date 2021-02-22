class CreateHospitals < ActiveRecord::Migration[6.0]
  def change
    create_table :hospitals do |t|
      t.string :status, null: false, default: "Active"
      t.string :description, limit: 255
      t.string :name, limit: 255
      t.string :street, limit: 255
      t.string :postal_code, limit: 255
      t.string :city, limit: 255
      t.string :province, limit: 255
      t.string :country, limit: 255
      t.string :phone, limit: 255

      t.belongs_to :warehouse
      t.belongs_to :user

      t.timestamps
    end

    add_reference :unpacking_events, :hospital
  end
end
