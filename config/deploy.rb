# frozen_string_literal: true

# config valid for current version and patch releases of Capistrano
lock "~> 3.19"

set :application, "korle-bu"
# Public repo: the server clones over HTTPS, so it holds no GitHub key
set :repo_url, "https://github.com/jessefalconer/korle-bu.git"
set :branch, ENV.fetch("BRANCH", "master")
set :deploy_to, "/home/deploy/#{fetch :application}"
set :keep_releases, 5

set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Ruby: rbenv in the deploy user's home, version from .ruby-version
set :rbenv_type, :user
set :rbenv_ruby, File.read(File.expand_path("../.ruby-version", __dir__)).strip

# Gems: installed per release into shared/bundle, without dev/test gems
set :bundle_config, { deployment: true, without: "development:test" }
set :bundle_jobs, 2

# Files and folders kept between releases.
# The production credentials key is copied to the server once by hand
# (see config/server/README.md); it is never committed.
append :linked_files, "config/credentials/production.key"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "vendor/bundle", "public/system", "storage"

# Assets are compiled on the server (dartsass + propshaft; no Node needed)
set :assets_roles, [:web]
set :migration_role, :db

# Puma runs as a systemd *user* service of the deploy user. Lingering (so the
# service runs without anyone logged in) is enabled once by the server setup
# script, because the deploy user has no sudo rights.
set :puma_systemctl_user, :user
set :puma_enable_lingering, false
set :puma_bind, "tcp://127.0.0.1:3000"
set :puma_service_unit_env_vars, ["RAILS_ENV=production", "MALLOC_ARENA_MAX=2"]
# Send Puma and Rails output to the systemd journal (rotated automatically):
#   journalctl --user -u korle-bu_puma_production -f
set :puma_access_log, false
set :puma_error_log, false
