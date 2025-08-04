# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_08_04_081157) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 191, null: false
    t.string "record_type", limit: 191, null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", limit: 191, null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "forecast_storage_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.binary "order", size: :medium
    t.index ["scenario_id"], name: "index_forecast_storage_orders_on_scenario_id", unique: true
  end

  create_table "heat_network_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.string "temperature", default: "mt"
    t.binary "order", size: :medium
    t.index ["scenario_id", "temperature"], name: "index_heat_network_orders_on_scenario_id_and_temperature", unique: true
    t.index ["scenario_id"], name: "index_heat_network_orders_on_scenario_id"
  end

  create_table "households_space_heating_producer_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.binary "order", size: :medium
    t.index ["scenario_id"], name: "index_households_space_heating_producer_orders_on_scenario_id", unique: true
  end

  create_table "hydrogen_demand_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.binary "order", size: :medium
    t.index ["scenario_id"], name: "index_hydrogen_demand_orders_on_scenario_id", unique: true
  end

  create_table "hydrogen_supply_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.binary "order", size: :medium
    t.index ["scenario_id"], name: "index_hydrogen_supply_orders_on_scenario_id", unique: true
  end

  create_table "scenario_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id", null: false
    t.string "key", null: false
    t.integer "source_scenario_id"
    t.string "source_scenario_title"
    t.integer "source_end_year"
    t.string "source_dataset_key"
    t.integer "source_saved_scenario_id"
    t.index ["scenario_id", "key"], name: "index_scenario_attachments_on_scenario_id_and_key", unique: true
    t.index ["scenario_id"], name: "index_scenario_attachments_on_scenario_id"
    t.index ["source_scenario_id"], name: "index_scenario_attachments_on_source_scenario_id"
  end

  create_table "scenario_scalings", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.string "area_attribute"
    t.float "value"
    t.float "base_value"
    t.boolean "has_agriculture", default: false, null: false
    t.boolean "has_industry", default: false, null: false
    t.boolean "has_energy", default: true, null: false
    t.index ["scenario_id"], name: "index_scenario_scalings_on_scenario_id", unique: true
  end

  create_table "scenario_users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id", null: false
    t.integer "role_id", null: false
    t.integer "user_id"
    t.string "user_email"
    t.index ["scenario_id", "user_email"], name: "scenario_users_scenario_id_user_email_idx", unique: true
    t.index ["scenario_id", "user_id"], name: "scenario_users_scenario_id_user_id_idx", unique: true
  end

  create_table "scenario_version_tags", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id", null: false
    t.integer "user_id", null: false
    t.text "description"
    t.index ["scenario_id", "user_id"], name: "index_scenario_version_tags_on_scenario_id_and_user_id", unique: true
  end

  create_table "scenarios", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "end_year", default: 2040
    t.boolean "keep_compatible", default: false, null: false
    t.boolean "private", default: false, null: false
    t.integer "preset_scenario_id"
    t.string "area_code"
    t.string "source"
    t.binary "user_values", size: :long
    t.binary "balanced_values", size: :medium
    t.binary "metadata", size: :medium
    t.binary "active_couplings", size: :medium
    t.index ["created_at"], name: "index_scenarios_on_created_at"
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "user_curves", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id", null: false
    t.string "key", null: false
    t.string "name"
    t.binary "curve", size: :medium, null: false
    t.integer "source_scenario_id"
    t.string "source_scenario_title"
    t.integer "source_saved_scenario_id"
    t.string "source_dataset_key"
    t.integer "source_end_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scenario_id", "key"], name: "index_user_curves_on_scenario_id_and_key", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.boolean "private_scenarios", default: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "include_in_qi_db", default: false
    t.string "user_email"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "forecast_storage_orders", "scenarios"
  add_foreign_key "heat_network_orders", "scenarios"
  add_foreign_key "households_space_heating_producer_orders", "scenarios"
  add_foreign_key "hydrogen_demand_orders", "scenarios"
  add_foreign_key "scenario_attachments", "scenarios"
  add_foreign_key "scenario_attachments", "scenarios", column: "source_scenario_id", name: "index_scenario_attachments_on_source_scenario_id"
end
