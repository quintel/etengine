# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160210114327) do

  create_table "fce_values", force: true do |t|
    t.string   "using_country"
    t.string   "origin_country"
    t.float    "co2_exploration_per_mj",     limit: 24
    t.float    "co2_extraction_per_mj",      limit: 24
    t.float    "co2_treatment_per_mj",       limit: 24
    t.float    "co2_transportation_per_mj",  limit: 24
    t.float    "co2_conversion_per_mj",      limit: 24
    t.float    "co2_waste_treatment_per_mj", limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "carrier"
  end

  create_table "flexibility_orders", force: true do |t|
    t.integer "scenario_id"
    t.text    "order"
  end

  add_index "flexibility_orders", ["scenario_id"], name: "index_flexibility_orders_on_scenario_id", unique: true, using: :btree

  create_table "gquery_groups", force: true do |t|
    t.string   "group_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  create_table "query_table_cells", force: true do |t|
    t.integer  "query_table_id"
    t.integer  "row"
    t.integer  "column"
    t.string   "name"
    t.text     "gquery"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "query_table_cells", ["query_table_id"], name: "index_query_table_cells_on_query_table_id", using: :btree

  create_table "query_tables", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "row_count"
    t.integer  "column_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scenario_scalings", force: true do |t|
    t.integer "scenario_id"
    t.string  "area_attribute"
    t.float   "value",           limit: 24
    t.float   "base_value",      limit: 24
    t.boolean "has_agriculture",            default: false, null: false
    t.boolean "has_industry",               default: false, null: false
    t.boolean "has_energy",                 default: true,  null: false
  end

  add_index "scenario_scalings", ["scenario_id"], name: "index_scenario_scalings_on_scenario_id", unique: true, using: :btree

  create_table "scenarios", force: true do |t|
    t.string   "author"
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "user_values"
    t.integer  "end_year",                     default: 2040
    t.boolean  "in_start_menu"
    t.integer  "user_id"
    t.integer  "preset_scenario_id"
    t.boolean  "use_fce"
    t.datetime "present_updated_at"
    t.integer  "protected",          limit: 1
    t.string   "area_code"
    t.string   "source"
    t.text     "balanced_values"
  end

  create_table "users", force: true do |t|
    t.string   "name",                                   null: false
    t.string   "email",                                  null: false
    t.string   "company_school"
    t.boolean  "allow_news",             default: true
    t.string   "heared_first_at",        default: ".."
    t.string   "password_salt"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "openid_identifier"
    t.string   "phone_number"
    t.string   "group"
    t.string   "trackable",              default: "0"
    t.boolean  "send_score",             default: false
    t.boolean  "new_round"
    t.string   "old_crypted_password"
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
  end

  add_index "users", ["trackable"], name: "index_users_on_trackable", using: :btree

end
