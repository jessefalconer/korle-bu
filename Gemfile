# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 8.1.4"

# Database
gem "pg", "~> 1.5"

# Web server
gem "puma", ">= 8.0.3"

# Assets: Propshaft serves files, importmap loads JavaScript without Node,
# dartsass-rails compiles the SCSS without Node
gem "dartsass-rails"
gem "importmap-rails"
gem "propshaft"

# Authentication / authorisation
gem "bcrypt", "~> 3.1.20"
gem "cancancan", "~> 3.6"

# Views and UI helpers
gem "chartkick"
gem "haml", "~> 7.5"
gem "kaminari"
gem "pg_search"

# CSV exports (no longer bundled with Ruby since 3.4)
gem "csv"

# Request throttling
gem "rack-attack"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "bullet"
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "factory_bot_rails"
  gem "rspec-rails", "~> 8.0"
end

group :development do
  # Deploys
  gem "capistrano", "~> 3.19", require: false
  gem "capistrano3-puma", "~> 8.1", require: false
  gem "capistrano-bundler", "~> 2.1", require: false
  gem "capistrano-rails", "~> 1.6", require: false
  gem "capistrano-rbenv", "~> 2.2", require: false
  # ed25519 SSH key support for net-ssh (Capistrano)
  gem "bcrypt_pbkdf", ">= 1.0", "< 2.0", require: false
  gem "ed25519", ">= 1.2", "< 2.0", require: false

  gem "rack-mini-profiler", require: false
  gem "rails-erd"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
