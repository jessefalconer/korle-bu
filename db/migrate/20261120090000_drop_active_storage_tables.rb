# frozen_string_literal: true

# Active Storage was only used for item photos, which were removed, and the
# DigitalOcean Spaces bucket it stored them in has been retired. Production still had
# 59 blob records (5 attached to items) pointing at files in that bucket.
#
# Rolling back recreates the empty tables; the old records and files are not restored.
class DropActiveStorageTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :active_storage_variant_records
    drop_table :active_storage_attachments
    drop_table :active_storage_blobs
  end

  def down
    create_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum, null: false
      t.datetime :created_at, precision: nil, null: false
      t.index :key, unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.string :record_type, null: false
      t.bigint :record_id, null: false
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }, index: true
      t.datetime :created_at, precision: nil, null: false
      t.index %i[record_type record_id name blob_id], name: "index_active_storage_attachments_uniqueness", unique: true
    end

    create_table :active_storage_variant_records do |t|
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }, index: false
      t.string :variation_digest, null: false
      t.index %i[blob_id variation_digest], name: "index_active_storage_variant_records_uniqueness", unique: true
    end
  end
end
