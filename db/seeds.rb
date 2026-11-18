# frozen_string_literal: true

# rubocop:disable Rails/Output -- prints progress and login details to the console

# Seeds development with a snapshot of production data (see lib/seed_snapshot.rb).
# Re-running replaces all app data in the database.
#
# You log in as the admin user with your own email: SEED_ADMIN_EMAIL if set,
# otherwise your `git config user.email`. Every seeded user's password is 123456.

require Rails.root.join("lib/seed_snapshot")

abort "Seeds load production snapshot data and only run in development." unless Rails.env.development?

admin_email = ENV["SEED_ADMIN_EMAIL"].presence || `git config user.email`.strip.presence
abort "Set SEED_ADMIN_EMAIL (or `git config user.email`) so the admin user has your email." unless admin_email

started = Time.current
SeedSnapshot.import(admin_email: admin_email)

puts "Seeded #{SeedSnapshot::TABLES.size} tables and #{User.count} users in #{(Time.current - started).round(1)}s."
puts "Log in as #{admin_email} / #{SeedSnapshot::PASSWORD} (Admin)."
User.where.not(role: "Admin").group(:role).minimum(:email).each do |role, email|
  puts "  #{role.ljust(18)} #{email} / #{SeedSnapshot::PASSWORD}"
end
# rubocop:enable Rails/Output
