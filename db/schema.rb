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

ActiveRecord::Schema[7.0].define(version: 2024_11_25_104913) do
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
    t.text "order"
    t.index ["scenario_id"], name: "index_forecast_storage_orders_on_scenario_id", unique: true
  end

  create_table "heat_network_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.text "order"
    t.string "temperature", default: "mt"
    t.index ["scenario_id", "temperature"], name: "index_heat_network_orders_on_scenario_id_and_temperature", unique: true
    t.index ["scenario_id"], name: "index_heat_network_orders_on_scenario_id"
  end

  create_table "households_space_heating_producer_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.text "order"
    t.index ["scenario_id"], name: "index_households_space_heating_producer_orders_on_scenario_id", unique: true
  end

  create_table "hydrogen_demand_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.text "order"
    t.index ["scenario_id"], name: "index_hydrogen_demand_orders_on_scenario_id", unique: true
  end

  create_table "hydrogen_supply_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.text "order"
    t.index ["scenario_id"], name: "index_hydrogen_supply_orders_on_scenario_id", unique: true
  end

  create_table "oauth_openid_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "access_grant_id", null: false
    t.string "nonce", null: false
    t.index ["access_grant_id"], name: "index_oauth_openid_requests_on_access_grant_id"
  end

  create_table "old_users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "company_school"
    t.boolean "allow_news", default: true
    t.string "heared_first_at", default: ".."
    t.string "password_salt"
    t.integer "role_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "openid_identifier"
    t.string "phone_number"
    t.string "group"
    t.string "trackable", limit: 191, default: "0"
    t.boolean "send_score", default: false
    t.boolean "new_round"
    t.string "old_crypted_password"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.index ["trackable"], name: "index_old_users_on_trackable"
  end

  create_table "personal_access_tokens", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "oauth_access_token_id", null: false
    t.string "name"
    t.datetime "last_used_at"
    t.index ["oauth_access_token_id"], name: "index_personal_access_tokens_on_oauth_access_token_id", unique: true
    t.index ["user_id"], name: "index_personal_access_tokens_on_user_id"
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
    t.text "user_values", size: :medium
    t.integer "end_year", default: 2040
    t.boolean "keep_compatible", default: false, null: false
    t.boolean "private", default: false, null: false
    t.integer "preset_scenario_id"
    t.string "area_code"
    t.string "source"
    t.text "balanced_values", size: :medium
    t.text "metadata"
    t.text "active_couplings", size: :medium
    t.index ["created_at"], name: "index_scenarios_on_created_at"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.boolean "private_scenarios", default: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "include_in_qi_db", default: false
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
