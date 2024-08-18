Korle-Bu is a non-profit organization shipping medical supplies and equipment to developing nations. https://kbnf.org/

## Getting Started & Tech
  Backend: Ruby on Rails. We suggest using RVM or rbenv to install version `2.6.5p114`. You can check your current version of ruby with `ruby -v`. More information on ruby: https://www.ruby-lang.org/en/documentation/installation/

  Database: PostgreSQL, use  `brew` or visit https://www.postgresql.org/ and install version `10.5`

  Templating, Style & More: HAML, SCSS, RSpec

  Some gems we use:
  * `aws-sdk` for S3 storage
  * `capistrano` for deployment
  * `factory-bot` for testing
  * `kaminar` for pagination
  * `cancancan` for permissions

### Setup Rails
* Clone the repository: `git@github.com:jessefalconer/korle-bu.git` and `cd` into the directory
* Install dependencies with `bundle install`
* Create the database with `rails db:create`
* Run any pending migrations with `rails db:migrate`
* Mass insert the SQL dump into pg with `psql kbnf_development < latest_pg_production_dump.sql.sql`
  * In the supplied .sql file, replace `deploy` with your db user name if `ERROR:  role "deploy" does not exist` is returned
  * Clean up the priveleges and roles:
    `CREATE ROLE "<my db user name>";
      GRANT ALL PRIVILEGES ON DATABASE kbnf_development TO "<my db user name>";
      REVOKE ALL ON SCHEMA public FROM PUBLIC;
      REVOKE ALL ON SCHEMA public FROM "<my db user name>";
      GRANT ALL ON SCHEMA public TO "<my db user name>";
      GRANT ALL ON SCHEMA public TO PUBLIC;`
* Seed users with `rails db:seed`
* Run the appropriate rake tasks (`rake --tasks` to view a list)
* Start the server with `rails s`

### Rails Convenience
* View http paths by running `rails routes` or visiting http://localhost:3000/rails/info/routes
* To lint your code and see possible style "offences" or errors, run `rubocop`. To automatically correct them run `rubocop -a`
* Run your tests with `rspec`

### ERD as of May 2021
[erd.pdf](https://github.com/jessefalconer/korle-bu/files/6436451/erd.pdf)
