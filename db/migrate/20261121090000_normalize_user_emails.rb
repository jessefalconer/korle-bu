# frozen_string_literal: true

# Emails become case-insensitive: stored lowercase, unique in the database.
# Stops (and lists them) if two accounts differ only by letter case, since
# merging people's accounts needs a human decision.
class NormalizeUserEmails < ActiveRecord::Migration[8.1]
  def up
    collisions = select_values(<<~SQL.squish)
      SELECT LOWER(TRIM(email)) FROM users GROUP BY LOWER(TRIM(email)) HAVING COUNT(*) > 1
    SQL
    if collisions.any?
      raise "These emails belong to more than one account once letter case is ignored. " \
            "Change or remove the extras, then rerun: #{collisions.join(", ")}"
    end

    execute "UPDATE users SET email = LOWER(TRIM(email)) WHERE email <> LOWER(TRIM(email))"
    add_index :users, :email, unique: true
  end

  def down
    remove_index :users, :email
  end
end
