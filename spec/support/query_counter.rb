# frozen_string_literal: true

module QueryCounter
  IGNORED_QUERY_NAMES = %w[SCHEMA CACHE].freeze

  # Returns the number of SQL queries run inside the block, ignoring schema lookups
  # and query-cache hits.
  def count_queries(&block)
    count = 0
    counter = lambda do |*, payload|
      next if payload[:cached] || IGNORED_QUERY_NAMES.include?(payload[:name])

      count += 1
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end

  # Requests `path`, checks that it rendered, and returns how many queries it ran.
  def queries_for_get(path)
    count = count_queries { get path }
    expect(response).to have_http_status(:ok)
    count
  end
end

RSpec.configure do |config|
  config.include QueryCounter
end
