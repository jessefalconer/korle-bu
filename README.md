Inventory and shipment tracking for [Korle-Bu Neuroscience Foundation](https://kbnf.org/), a non-profit shipping medical supplies and equipment to developing nations.

## Tech

- **Rails 8.1** on **Ruby 4.0** (pinned in `.ruby-version`)
- **PostgreSQL**
- **Propshaft** for assets, **importmap-rails** for JavaScript and **dartsass-rails** for SCSS, so there's no Node or Yarn build step
- **HAML** views, **Bootstrap 5.3**, jQuery and jQuery UI. Bootstrap's SCSS source is vendored in `vendor/assets/stylesheets/bootstrap` and configured in `app/assets/stylesheets/_bootstrap-custom.scss` (brand colours, and Bootstrap 3's breakpoints and type sizes, which the custom stylesheets were built around); the scripts are in `vendor/javascript`
- **Puma** in development and production
- **RSpec** and FactoryBot for tests, **RuboCop** for linting

Notable gems: `cancancan` (permissions), `kaminari` (pagination), `pg_search` (search), `chartkick` (dashboard charts), `aws-sdk-s3` (Active Storage on DigitalOcean Spaces), `rack-attack` (request throttling), `capistrano` (deploys).

## Setup

Install the pinned Ruby with rbenv (on Homebrew). It reads `.ruby-version` automatically once it's initialized in your shell (`eval "$(rbenv init -)"`):

```bash
rbenv install
```

Then install dependencies and set up the database:

```bash
bundle install
bin/rails db:setup
bin/dev
```

`db:setup` creates the database, loads `db/schema.rb` and runs the seeds. `bin/dev` starts the Rails server and the Sass watcher together (see `Procfile.dev`). Visit http://localhost:3000.

### Seed data

`bin/rails db:seed` replaces all app data in development with a snapshot of production (`db/seeds/snapshot`, one gzipped CSV per table, loaded in about 15 seconds). No production users are in the snapshot. Seeding creates placeholder users for every user the data references:

- **Admin:** your email (`SEED_ADMIN_EMAIL`, or your `git config user.email` if that isn't set)
- **Other roles:** `user<id>@example.com`, printed when seeding finishes
- **Password for everyone:** `123456`

All seeded users belong to the warehouse holding the most received stock, so the received and unpacking pages have data.

To refresh the snapshot from a new production dump:

```bash
pg_dump --no-owner --no-acl --exclude-table-data=users -d <production_db> -f dump.sql   # on the server
createdb kbnf_prod_scratch && psql -d kbnf_prod_scratch -f dump.sql                     # locally
bin/rails seed_snapshot:export SOURCE_DB=kbnf_prod_scratch
```

The export blanks columns that hold details about real people (see `SCRUBBED_COLUMNS` in `lib/seed_snapshot.rb`). Add new ones there when the schema gains them.

## Development

- **Tests:** `bundle exec rspec`
- **Lint:** `bundle exec rubocop` (`-a` to autocorrect)
- **Routes:** `bin/rails routes`, or http://localhost:3000/rails/info/routes
- **JavaScript** is served as-is through import maps (`config/importmap.rb`); there's nothing to build.
- **SCSS** is compiled by `bin/rails dartsass:watch` (run by `bin/dev`), or once with `bin/rails dartsass:build`.
- **Database in use:** if `db:drop` or `db:reset` fails because other sessions are connected, run `bin/rails kpsql` to end them.

## Deployment

Deploys use Capistrano to a single server (see `config/deploy/production.rb`). They deploy `master` from GitHub, or another branch with `BRANCH=<name>`:

```bash
bundle exec cap production deploy
```

The deploy installs gems, precompiles assets, runs migrations and restarts Puma, which runs as a systemd user service (`journalctl --user -u korle-bu_puma_production -f` on the server for logs).

- **Secrets:** production credentials live in `config/credentials/production.yml.enc`. The key, `config/credentials/production.key`, is a linked file in the server's `shared/` directory and isn't in git.
- **Database:** the app connects over PostgreSQL's local Unix socket with peer authentication, so there's no database password (see `config/database.yml`).

## Legacy data

`lib/tasks/legacy_data.rake` holds the one-time tasks that migrated the original schema (`big_items`, `item_boxes`) into the current model. They aren't part of normal setup.

## ERD

[erd.pdf](erd.pdf) was last generated in May 2021, so columns added since then are missing. Regenerate it with `bundle exec erd` (uses the `rails-erd` gem; needs Graphviz: `brew install graphviz`).
