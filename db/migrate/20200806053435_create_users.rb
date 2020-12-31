class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :email, limit: 255
      t.string :first_name, limit: 255
      t.string :last_name, limit: 255
      t.string :phone, limit: 255
      t.string :password_digest, limit: 255
      t.string :status, limit: 255, null: false, default: "Deactivated"
      t.text :notes

      t.timestamps
    end
  end
end
