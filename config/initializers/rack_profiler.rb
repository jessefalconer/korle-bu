# frozen_string_literal: true

if Rails.env.development?
  require "rack-mini-profiler"

  Rack::MiniProfiler.config.position = "bottom-left"
  Rack::MiniProfiler.config.show_total_sql_count = true
  Rack::MiniProfiler.config.skip_schema_queries = true

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
