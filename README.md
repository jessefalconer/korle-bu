Inventory and shipment tracking for [Korle-Bu Neuroscience Foundation](https://kbnf.org/), a non-profit shipping medical supplies and equipment to developing nations.

## Tech

- **Rails 6.1** on **Ruby 2.6.5** (pinned in `.ruby-version`)
- **PostgreSQL** (production runs 12)
- **Webpacker** with **Node 16** (pinned in `.node-version`) and **Yarn 1** for JavaScript; Sprockets for SCSS
- **HAML** views, Bootstrap 3, jQuery and jQuery UI
- **RSpec** and FactoryBot for tests, **RuboCop** for linting

Notable gems: `cancancan` (permissions), `kaminari` (pagination), `pg_search` (search), `chartkick` (dashboard charts), `aws-sdk-s3` (Active Storage on DigitalOcean Spaces), `capistrano` (deploys).

## Setup

Install the pinned Ruby and Node with a version manager, e.g. rbenv and nodenv (both on Homebrew). They read `.ruby-version` and `.node-version` automatically once initialized in your shell:

```bash
rbenv install
nodenv install
npm install -g yarn@1
```

Then install dependencies and set up the database:

```bash
bundle install
yarn install
bin/rails db:setup
bin/rails server
```

`db:setup` creates the database, loads `db/schema.rb` and runs the seeds. Visit http://localhost:3000.

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
- **JavaScript** compiles on demand when a page requests it. `bin/webpack` builds it ahead of time.
- **Database in use:** if `db:drop` or `db:reset` fails because other sessions are connected, run `bin/rails kpsql` to end them.

### Troubleshooting (macOS)

- **Commands hang under Spring:** set `DISABLE_SPRING=1`.
- **Pack requests fail with `ECONNREFUSED localhost:3035`:** Ruby 2.6's socket check misreports closed ports on recent macOS, so Webpacker thinks the dev server is running. `config/initializers/webpacker_dev_server_check.rb` works around this in development; make sure you haven't removed it.

## Deployment

Deploys use Capistrano to a single server (see `config/deploy/production.rb`):

```bash
bundle exec cap production deploy
```

The deploy runs `yarn install` before precompiling assets. **The server runs Node 12**, older than `.node-version`, so JavaScript dependencies must install on Node 12; `resolutions` in `package.json` caps packages that need newer Node. Production secrets are managed with `capistrano-secrets-yml`, and the database connection comes from `DATABASE_URL` and `KBNF_DATABASE_PASSWORD` on the server.

## Legacy data

`lib/tasks/legacy_data.rake` holds the one-time tasks that migrated the original schema (`big_items`, `item_boxes`) into the current model. They aren't part of normal setup.

## ERD

[erd.pdf](erd.pdf) was last generated in May 2021, so columns added since then are missing. Regenerate it with `bundle exec erd` (uses the `rails-erd` gem; needs Graphviz: `brew install graphviz`).
