Korle-Bu is a non-profit organization shipping medical supplies and equipment to developing nations. https://kbnf.org/

## Getting started
  Backend: Ruby on Rails. We suggest using RVM or rbenv to install version `2.6.5p114`. You can check your current version of ruby with `ruby -v`. More information on ruby: https://www.ruby-lang.org/en/documentation/installation/
  
  Database: PostgreSQL, use  `brew` or visit https://www.postgresql.org/ and install version `10.5`

### Setup Rails
* Clone the repository: `git@github.com:jessefalconer/korle-bu.git` and `cd` into the directory
* Install dependencies with `bundle install`
* Create the database with `rails db:create`
* Run any pending migrations with `rails db:migrate`
* Seed the database with `rails db:seed`
* Start the server with `rails s`

### Rails Convenience
* View http paths by running `rails routes` or visiting http://localhost:3000/rails/info/routes
* To lint your code and see possible style "offences" or errors, run `rubocop`. To automatically correct them run `rubocop -a`

### ERD as of August 2020
[erd.pdf](https://github.com/jessefalconer/korle-bu/files/5180316/erd.pdf)
