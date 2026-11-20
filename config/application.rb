# frozen_string_literal: true

require_relative "boot"

# Every framework except Active Storage, Action Text and Action Mailbox: the app stores
# no files (photo uploads were removed and the DigitalOcean Spaces bucket retired), and
# the other two depend on Active Storage.
require "rails"
require "active_record/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kbnf
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    config.autoload_lib(ignore: %w[assets tasks capistrano])

    # The app was built before Rails 7; keep its existing behaviour where the
    # newer defaults would change what users see or what is stored.
    #
    # Sessions and cookies were already JSON-serialised (see the old
    # cookies_serializer initializer), so this only makes it explicit.
    config.action_dispatch.cookies_serializer = :json

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
