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

ActiveRecord::Schema.define(version: 2020_08_07_195348) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "boxed_items", force: :cascade do |t|
    t.integer "quantity"
    t.boolean "expires"
    t.datetime "expiry_date"
    t.integer "custom_uid"
    t.bigint "box_id"
    t.bigint "item_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["box_id"], name: "index_boxed_items_on_box_id"
    t.index ["item_id"], name: "index_boxed_items_on_item_id"
    t.index ["user_id"], name: "index_boxed_items_on_user_id"
  end

  create_table "boxes", force: :cascade do |t|
    t.string "status"
    t.string "notes"
    t.string "name"
    t.integer "custom_uid"
    t.bigint "user_id"
    t.bigint "container_id"
    t.bigint "pallet_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["container_id"], name: "index_boxes_on_container_id"
    t.index ["pallet_id"], name: "index_boxes_on_pallet_id"
    t.index ["user_id"], name: "index_boxes_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "containerized_items", force: :cascade do |t|
    t.integer "quantity"
    t.boolean "expires"
    t.datetime "expiry_date"
    t.integer "custom_uid"
    t.bigint "container_id"
    t.bigint "item_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["container_id"], name: "index_containerized_items_on_container_id"
    t.index ["item_id"], name: "index_containerized_items_on_item_id"
    t.index ["user_id"], name: "index_containerized_items_on_user_id"
  end

  create_table "containers", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.string "notes"
    t.integer "custom_uid"
    t.bigint "user_id"
    t.bigint "shipment_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["shipment_id"], name: "index_containers_on_shipment_id"
    t.index ["user_id"], name: "index_containers_on_user_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "object"
    t.string "brand"
    t.string "standardized_size"
    t.float "concentration"
    t.string "concentration_units"
    t.string "concentration_description"
    t.float "numerical_size_1"
    t.string "numerical_units_1"
    t.string "numerical_description_1"
    t.float "numerical_size_2"
    t.string "numerical_units_2"
    t.string "numerical_description_2"
    t.integer "packaged_quantity"
    t.string "generated_name"
    t.string "notes"
    t.boolean "verified"
    t.bigint "user_id"
    t.bigint "category_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["category_id"], name: "index_items_on_category_id"
    t.index ["user_id"], name: "index_items_on_user_id"
  end

  create_table "palletized_items", force: :cascade do |t|
    t.integer "quantity"
    t.boolean "expires"
    t.datetime "expiry_date"
    t.integer "custom_uid"
    t.bigint "pallet_id"
    t.bigint "item_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["item_id"], name: "index_palletized_items_on_item_id"
    t.index ["pallet_id"], name: "index_palletized_items_on_pallet_id"
    t.index ["user_id"], name: "index_palletized_items_on_user_id"
  end

  create_table "pallets", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.string "notes"
    t.integer "custom_uid"
    t.bigint "user_id"
    t.bigint "container_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["container_id"], name: "index_pallets_on_container_id"
    t.index ["user_id"], name: "index_pallets_on_user_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.string "notes"
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
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "password_digest"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "status"
    t.string "description"
    t.string "name"
    t.string "street"
    t.string "postal_code"
    t.string "city"
    t.string "province"
    t.string "country"
    t.integer "identifier"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_warehouses_on_user_id"
  end

  add_foreign_key "shipments", "warehouses", column: "receiving_warehouse_id"
  add_foreign_key "shipments", "warehouses", column: "shipping_warehouse_id"
end
