# frozen_string_literal: true

# Deploy to the production hostname. Before DNS points at a new server, pass
# its address instead: SERVER_HOST=203.0.113.10 bundle exec cap production deploy
server ENV.fetch("SERVER_HOST", "inventory.kbnf.org"), user: "deploy", roles: %w[app db web]

set :rails_env, "production"

set :ssh_options, {
  # Never forward your SSH agent to the server; it clones the (public) repo
  # over HTTPS and needs no GitHub credentials at all.
  forward_agent: false,
  auth_methods: %w[publickey],
  # Refuse to connect if the server's host key ever changes unexpectedly.
  verify_host_key: :always
}
