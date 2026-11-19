# frozen_string_literal: true

# Set when an admin creates an account or resets someone's password with a
# temporary one; the user must choose their own password at next login.
# Existing users default to false, so nobody is forced to change today.
class AddMustChangePasswordToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :must_change_password, :boolean, default: false, null: false
  end
end
