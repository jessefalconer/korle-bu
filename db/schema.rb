# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_31_232745) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "big_items", force: :cascade do |t|
    t.integer "weight"
    t.string "description"
    t.string "destination"
    t.string "category"
    t.text "notes"
    t.bigint "container_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["container_id"], name: "index_big_items_on_container_id"
  end

  create_table "boxes", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "status", limit: 255, default: "Not Started"
    t.string "notes", limit: 255
    t.integer "custom_uid"
    t.integer "weight"
    t.bigint "user_id"
    t.bigint "pallet_id"
    t.bigint "container_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "number"
    t.index ["container_id"], name: "index_boxes_on_container_id"
    t.index ["pallet_id"], name: "index_boxes_on_pallet_id"
    t.index ["user_id"], name: "index_boxes_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "containers", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "status", limit: 255, default: "Not Started"
    t.string "notes", limit: 255
    t.integer "custom_uid"
    t.bigint "user_id"
    t.bigint "shipment_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "destination"
    t.index ["shipment_id"], name: "index_containers_on_shipment_id"
    t.index ["user_id"], name: "index_containers_on_user_id"
  end

  create_table "item_boxes", force: :cascade do |t|
    t.integer "quantity", default: 0, null: false
    t.integer "weight"
    t.datetime "item_expire"
    t.bigint "box_id"
    t.bigint "item_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["box_id"], name: "index_item_boxes_on_box_id"
    t.index ["item_id"], name: "index_item_boxes_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "object", limit: 255
    t.string "brand", limit: 255
    t.string "standardized_size", limit: 255
    t.float "concentration"
    t.string "concentration_units", limit: 255
    t.string "concentration_description", limit: 255
    t.float "numerical_size_1"
    t.string "numerical_units_1", limit: 255
    t.string "numerical_description_1", limit: 255
    t.float "numerical_size_2"
    t.string "numerical_units_2", limit: 255
    t.string "numerical_description_2", limit: 255
    t.integer "packaged_quantity"
    t.string "generated_name"
    t.string "generated_name_with_keywords"
    t.string "notes", limit: 255
    t.string "keywords", limit: 255
    t.boolean "verified", default: false, null: false
    t.boolean "flagged", default: false, null: false
    t.bigint "user_id"
    t.bigint "category_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "category"
    t.index ["category_id"], name: "index_items_on_category_id"
    t.index ["user_id"], name: "index_items_on_user_id"
  end

  create_table "packed_items", force: :cascade do |t|
    t.integer "quantity", default: 0, null: false
    t.integer "weight"
    t.string "weight_units"
    t.datetime "expiry_date"
    t.bigint "box_id"
    t.bigint "pallet_id"
    t.bigint "container_id"
    t.bigint "shipment_id"
    t.bigint "item_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["box_id"], name: "index_packed_items_on_box_id"
    t.index ["container_id"], name: "index_packed_items_on_container_id"
    t.index ["item_id"], name: "index_packed_items_on_item_id"
    t.index ["pallet_id"], name: "index_packed_items_on_pallet_id"
    t.index ["shipment_id"], name: "index_packed_items_on_shipment_id"
    t.index ["user_id"], name: "index_packed_items_on_user_id"
  end

  create_table "pallets", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "status", limit: 255, default: "Not Started"
    t.string "notes", limit: 255
    t.integer "custom_uid"
    t.bigint "user_id"
    t.bigint "container_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "location"
    t.string "description"
    t.index ["container_id"], name: "index_pallets_on_container_id"
    t.index ["user_id"], name: "index_pallets_on_user_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "status", default: "Not Started", null: false
    t.text "notes"
    t.integer "custom_uid"
    t.bigint "user_id"
    t.bigint "receiving_warehouse_id"
    t.bigint "shipping_warehouse_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["receiving_warehouse_id"], name: "index_shipments_on_receiving_warehouse_id"
    t.index ["shipping_warehouse_id"], name: "index_shipments_on_shipping_warehouse_id"
    t.index ["user_id"], name: "index_shipments_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", limit: 255
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.string "phone", limit: 255
    t.string "password_digest", limit: 255
    t.string "status", limit: 255, default: "Deactivated", null: false
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "role", default: "Volunteer", null: false
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "status", default: "Active", null: false
    t.string "description", limit: 255
    t.string "name", limit: 255
    t.string "street", limit: 255
    t.string "postal_code", limit: 255
    t.string "city", limit: 255
    t.string "province", limit: 255
    t.string "country", limit: 255
    t.integer "custom_uid"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_warehouses_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "shipments", "warehouses", column: "receiving_warehouse_id"
  add_foreign_key "shipments", "warehouses", column: "shipping_warehouse_id"
end
