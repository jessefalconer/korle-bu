# frozen_string_literal: true

# Custom dashboard achievements were removed from the app. Rolling back brings
# the columns back empty; the achievements saved in them are not restored.
class RemoveUserAchievements < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.remove :achiever_name, type: :string
      t.remove :achievement_title, type: :string
      t.remove :achievement_description, type: :string
      t.remove :achievement_value, type: :integer
      t.remove :achievement_max_value, type: :integer
    end
  end
end
