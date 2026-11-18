# frozen_string_literal: true

desc "Terminate other connections to this environment's database (e.g. before db:drop or db:reset)"
task kpsql: :environment do
  conn = ActiveRecord::Base.connection
  terminated = conn.select_values(<<~SQL).count(true)
    SELECT pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE datname = current_database() AND pid <> pg_backend_pid()
  SQL

  puts "Terminated #{terminated} connection(s) to #{conn.current_database}."
end
