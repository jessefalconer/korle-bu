# frozen_string_literal: true

# rubocop:disable Rails/Output -- prints progress and login details to the console

require "csv"
require "zlib"

# Loads (and regenerates) the development seed data: a snapshot of production
# stored as one gzipped CSV per table in db/seeds/snapshot.
#
# Users are never exported. Seeding creates placeholder users for every user_id
# the snapshot references, so production accounts never end up in the repo.
module SeedSnapshot
  DIR = Rails.root.join("db/seeds/snapshot")

  # Load order. Only shipments -> warehouses is enforced by a foreign key today.
  TABLES = %w[
    warehouses categories hospitals items
    shipments containers pallets boxes packed_items unpacking_events
    big_items item_boxes
  ].freeze

  USER_REFERENCING_TABLES = %w[
    warehouses categories hospitals items
    shipments containers pallets boxes packed_items unpacking_events
  ].freeze

  # Columns holding details about real people, exported as NULL.
  SCRUBBED_COLUMNS = {
    "hospitals" => %w[point_of_contact_name point_of_contact_phone]
  }.freeze

  ADMIN_USER_ID = 1
  PASSWORD = "123456"
  OTHER_ROLES = (User::ROLES - ["Admin"]).freeze

  module_function

  # Writes every table in TABLES from `source` (a PG::Connection to a restored dump).
  def export(source)
    FileUtils.mkdir_p(DIR)

    TABLES.each do |table|
      path = DIR.join("#{table}.csv.gz")
      Zlib::GzipWriter.open(path, Zlib::BEST_COMPRESSION) do |gz|
        sql = "COPY (SELECT #{select_list(source, table)} FROM #{source.quote_ident(table)} ORDER BY 1) " \
              "TO STDOUT WITH (FORMAT csv, HEADER)"
        source.copy_data(sql) do
          while (row = source.get_copy_data)
            gz.write(row)
          end
        end
      end
      puts "  #{table.ljust(18)} #{File.size(path).to_s.rjust(9)} bytes"
    end
  end

  def select_list(source, table)
    scrubbed = SCRUBBED_COLUMNS.fetch(table, [])
    columns = source.exec_params(
      "SELECT column_name FROM information_schema.columns " \
      "WHERE table_schema = 'public' AND table_name = $1 ORDER BY ordinal_position",
      [table]
    ).column_values(0)

    columns.map do |column|
      quoted = source.quote_ident(column)
      scrubbed.include?(column) ? "NULL AS #{quoted}" : quoted
    end.join(", ")
  end

  # Replaces all app data in the current database with the snapshot.
  def import(admin_email:)
    conn = ActiveRecord::Base.connection

    conn.transaction do
      conn.execute("TRUNCATE #{(TABLES + ["users"]).join(", ")} RESTART IDENTITY CASCADE")

      TABLES.each { |table| copy_in(conn.raw_connection, table) }
      create_users(referenced_user_ids(conn), admin_email, busiest_receiving_warehouse_id(conn))

      (TABLES + ["users"]).each { |table| conn.reset_pk_sequence!(table) }
    end
  end

  def copy_in(raw, table)
    Zlib::GzipReader.open(DIR.join("#{table}.csv.gz")) do |gz|
      columns = CSV.parse_line(gz.gets).map { |column| raw.quote_ident(column) }.join(", ")

      raw.copy_data("COPY #{raw.quote_ident(table)} (#{columns}) FROM STDIN WITH (FORMAT csv)") do
        while (chunk = gz.read(64 * 1024))
          raw.put_copy_data(chunk)
        end
      end
    end
  end

  def referenced_user_ids(conn)
    union = USER_REFERENCING_TABLES.map { |table| "SELECT user_id FROM #{table}" }.join(" UNION ")
    ids = conn.select_values("SELECT DISTINCT user_id FROM (#{union}) refs WHERE user_id IS NOT NULL")
    (ids.map(&:to_i) | [ADMIN_USER_ID]).sort
  end

  # Received/unpacking pages only show stock in the current user's warehouse, so seeded
  # users belong to the warehouse holding the most received stock.
  def busiest_receiving_warehouse_id(conn)
    conn.select_value(<<~SQL)
      SELECT shipments.receiving_warehouse_id
      FROM packed_items
      JOIN shipments ON shipments.id = packed_items.shipment_id
      WHERE packed_items.remaining_quantity > 0 AND shipments.receiving_warehouse_id IS NOT NULL
      GROUP BY 1
      ORDER BY COUNT(*) DESC
      LIMIT 1
    SQL
  end

  def create_users(ids, admin_email, warehouse_id)
    ids.each_with_index do |id, index|
      admin = id == ADMIN_USER_ID

      User.create!(
        id: id,
        warehouse_id: warehouse_id,
        email: admin ? admin_email : "user#{id}@example.com",
        first_name: admin ? "Dev" : "User",
        last_name: admin ? "Admin" : id.to_s,
        phone: "604-555-#{id.to_s.rjust(4, "0")}",
        password: PASSWORD,
        status: "Active",
        role: admin ? "Admin" : OTHER_ROLES[index % OTHER_ROLES.size]
      )
    end
  end
end
# rubocop:enable Rails/Output
