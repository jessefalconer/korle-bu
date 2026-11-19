# frozen_string_literal: true

# Puma configuration, used both locally (bin/rails server) and in production,
# where systemd starts it with `bundle exec puma -e production`.

# Threads per process. Rails 8's default; plenty for this app's traffic.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

if ENV.fetch("RAILS_ENV", "development") == "production"
  # nginx proxies to Puma; only accept connections from the server itself.
  # (The firewall blocks port 3000 from outside too.)
  bind "tcp://127.0.0.1:3000"

  # A single process keeps memory predictable on the 2 GB droplet.
  # Raise WEB_CONCURRENCY (processes) only if the server gets more RAM and CPU.
  workers ENV.fetch("WEB_CONCURRENCY", 0)
else
  port ENV.fetch("PORT", 3000)
end

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Only use a pidfile when requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
