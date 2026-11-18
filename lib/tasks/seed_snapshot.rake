# frozen_string_literal: true

namespace :seed_snapshot do
  desc "Regenerate db/seeds/snapshot from a restored production dump, e.g. SOURCE_DB=kbnf_prod_scratch"
  task export: :environment do
    require Rails.root.join("lib/seed_snapshot")

    source = PG.connect(dbname: ENV.fetch("SOURCE_DB") { abort "Set SOURCE_DB to the database holding the restored dump." })
    puts "Exporting from #{source.db} to #{SeedSnapshot::DIR.relative_path_from(Rails.root)}:"
    SeedSnapshot.export(source)
  ensure
    source&.close
  end
end
