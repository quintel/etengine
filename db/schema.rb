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

ActiveRecord::Schema[7.0].define(version: 2022_12_06_162002) do
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

  create_table "fce_values", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "using_country"
    t.string "origin_country"
    t.float "co2_exploration_per_mj"
    t.float "co2_extraction_per_mj"
    t.float "co2_treatment_per_mj"
    t.float "co2_transportation_per_mj"
    t.float "co2_conversion_per_mj"
    t.float "co2_waste_treatment_per_mj"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "carrier"
  end

  create_table "gquery_groups", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "group_key"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "description"
  end

  create_table "heat_network_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.text "order"
    t.index ["scenario_id"], name: "index_heat_network_orders_on_scenario_id", unique: true
  end

  create_table "oauth_access_grants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri"
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.boolean "first_party", default: false, null: false
    t.integer "owner_id", null: false
    t.string "owner_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_openid_requests", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "personal_access_tokens", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "oauth_access_token_id", null: false
    t.string "name"
    t.datetime "last_used_at"
    t.index ["oauth_access_token_id"], name: "index_personal_access_tokens_on_oauth_access_token_id", unique: true
    t.index ["user_id"], name: "index_personal_access_tokens_on_user_id"
  end

  create_table "query_table_cells", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "query_table_id"
    t.integer "row"
    t.integer "column"
    t.string "name"
    t.text "gquery"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["query_table_id"], name: "index_query_table_cells_on_query_table_id"
  end

  create_table "query_tables", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "row_count"
    t.integer "column_count"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "roles", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
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

  create_table "scenarios", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "author"
    t.string "old_title"
    t.text "old_description"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "user_values", size: :medium
    t.integer "end_year", default: 2040
    t.boolean "api_read_only", default: false
    t.boolean "keep_compatible", default: false
    t.boolean "in_start_menu"
    t.bigint "user_id"
    t.integer "preset_scenario_id"
    t.boolean "use_fce"
    t.datetime "present_updated_at", precision: nil
    t.string "area_code"
    t.string "source"
    t.text "balanced_values", size: :medium
    t.text "metadata"
    t.index ["created_at"], name: "index_scenarios_on_created_at"
    t.index ["user_id"], name: "index_scenarios_on_user_id"
  end

  create_table "staff_applications", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.bigint "application_id", null: false
    t.index ["application_id"], name: "fk_rails_6768c0af4c"
    t.index ["user_id", "name"], name: "index_staff_applications_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_staff_applications_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "legacy_password_salt"
    t.string "name", default: "", null: false
    t.boolean "admin", default: false, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "heat_network_orders", "scenarios"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "oauth_openid_requests", "oauth_access_grants", column: "access_grant_id", on_delete: :cascade
  add_foreign_key "personal_access_tokens", "oauth_access_tokens"
  add_foreign_key "personal_access_tokens", "users"
  add_foreign_key "scenario_attachments", "scenarios"
  add_foreign_key "scenario_attachments", "scenarios", column: "source_scenario_id", name: "index_scenario_attachments_on_source_scenario_id"
  add_foreign_key "scenarios", "users"
  add_foreign_key "staff_applications", "oauth_applications", column: "application_id"
  add_foreign_key "staff_applications", "users"
end
