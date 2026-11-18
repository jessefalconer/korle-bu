# frozen_string_literal: true

# Webpacker decides whether webpack-dev-server is up with
# `Socket.tcp(host, port, connect_timeout: ...)`. On Ruby 2.6 with recent macOS that
# call reports success for any closed port, so Webpacker always proxies /packs to a
# dev server that isn't running (500s) and never compiles packs on demand.
#
# Do the same check with a plain connect bounded by Timeout instead. Development only.
if Rails.env.development?
  require "socket"
  require "timeout"

  module WebpackerDevServerCheck
    def running?
      return false if config.dev_server.blank?

      Timeout.timeout(connect_timeout) { Socket.tcp(host, port).close }
      true
    rescue StandardError
      false
    end
  end

  Webpacker::DevServer.prepend(WebpackerDevServerCheck)
end
