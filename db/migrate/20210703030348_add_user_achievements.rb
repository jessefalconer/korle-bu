class AddUserAchievements < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :achiever_name, :string
    add_column :users, :achievement_title, :string
    add_column :users, :achievement_description, :string
    add_column :users, :achievement_value, :integer
    add_column :users, :achievement_max_value, :integer
  end
end
