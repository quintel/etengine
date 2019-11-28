# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_11_27_175656) do

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 191, null: false
    t.string "record_type", limit: 191, null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", limit: 191, null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "fce_values", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "using_country"
    t.string "origin_country"
    t.float "co2_exploration_per_mj"
    t.float "co2_extraction_per_mj"
    t.float "co2_treatment_per_mj"
    t.float "co2_transportation_per_mj"
    t.float "co2_conversion_per_mj"
    t.float "co2_waste_treatment_per_mj"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "carrier"
  end

  create_table "flexibility_orders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.text "order"
    t.index ["scenario_id"], name: "index_flexibility_orders_on_scenario_id", unique: true
  end

  create_table "gquery_groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "group_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
  end

  create_table "heat_network_orders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "scenario_id"
    t.text "order"
    t.index ["scenario_id"], name: "index_heat_network_orders_on_scenario_id", unique: true
  end

  create_table "query_table_cells", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "query_table_id"
    t.integer "row"
    t.integer "column"
    t.string "name"
    t.text "gquery"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["query_table_id"], name: "index_query_table_cells_on_query_table_id"
  end

  create_table "query_tables", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "row_count"
    t.integer "column_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scenario_scalings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "scenario_id"
    t.string "area_attribute"
    t.float "value"
    t.float "base_value"
    t.boolean "has_agriculture", default: false, null: false
    t.boolean "has_industry", default: false, null: false
    t.boolean "has_energy", default: true, null: false
    t.index ["scenario_id"], name: "index_scenario_scalings_on_scenario_id", unique: true
  end

  create_table "scenarios", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "author"
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "user_values", limit: 16777215
    t.integer "end_year", default: 2040
    t.boolean "in_start_menu"
    t.integer "user_id"
    t.integer "preset_scenario_id"
    t.boolean "use_fce"
    t.datetime "present_updated_at"
    t.boolean "protected"
    t.string "area_code"
    t.string "source"
    t.text "balanced_values", limit: 16777215
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "company_school"
    t.boolean "allow_news", default: true
    t.string "heared_first_at", default: ".."
    t.string "password_salt"
    t.integer "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "openid_identifier"
    t.string "phone_number"
    t.string "group"
    t.string "trackable", limit: 191, default: "0"
    t.boolean "send_score", default: false
    t.boolean "new_round"
    t.string "old_crypted_password"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.index ["trackable"], name: "index_users_on_trackable"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "heat_network_orders", "scenarios"
end
