# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# concurrent-ruby >= 1.3.5 no longer requires logger, but Rails < 7.1 expects
# ::Logger to be loaded before ActiveSupport. Remove after upgrading Rails.
require "logger"
