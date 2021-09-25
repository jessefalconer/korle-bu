class AddGpsCoordsToHospitals < ActiveRecord::Migration[6.0]
  def change
    add_column :hospitals, :longitude, :string
    add_column :hospitals, :latitude, :string
  end
end
