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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120806130345) do

  create_table "blueprint_layouts", :force => true do |t|
    t.string   "key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blueprint_models", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "converter_positions", :force => true do |t|
    t.integer  "converter_id"
    t.integer  "x"
    t.integer  "y"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hidden"
    t.integer  "blueprint_layout_id"
    t.string   "converter_key"
  end

  add_index "converter_positions", ["converter_id"], :name => "index_converter_positions_on_converter_id"

  create_table "energy_balance_groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "graphviz_color"
    t.integer  "graphviz_default_x"
  end

  create_table "fce_values", :force => true do |t|
    t.string   "using_country"
    t.string   "origin_country"
    t.float    "co2_exploration_per_mj"
    t.float    "co2_extraction_per_mj"
    t.float    "co2_treatment_per_mj"
    t.float    "co2_transportation_per_mj"
    t.float    "co2_conversion_per_mj"
    t.float    "co2_waste_treatment_per_mj"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "carrier"
  end

  create_table "gquery_groups", :force => true do |t|
    t.string   "group_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  create_table "groups", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key"
    t.string   "shortcut"
    t.integer  "group_id"
  end

  add_index "groups", ["group_id"], :name => "index_groups_on_group_id"

  create_table "query_table_cells", :force => true do |t|
    t.integer  "query_table_id"
    t.integer  "row"
    t.integer  "column"
    t.string   "name"
    t.text     "gquery"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "query_table_cells", ["query_table_id"], :name => "index_query_table_cells_on_query_table_id"

  create_table "query_tables", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "row_count"
    t.integer  "column_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scenarios", :force => true do |t|
    t.string   "author"
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "user_values"
    t.integer  "end_year",                        :default => 2040
    t.boolean  "in_start_menu"
    t.integer  "user_id"
    t.integer  "preset_scenario_id"
    t.boolean  "use_fce"
    t.datetime "present_updated_at"
    t.integer  "protected",          :limit => 1
    t.string   "area_code"
    t.string   "source"
  end

  add_index "scenarios", ["source"], :name => "index_scenarios_on_source"

  create_table "users", :force => true do |t|
    t.string   "name",                                  :null => false
    t.string   "email",                                 :null => false
    t.string   "company_school"
    t.boolean  "allow_news",         :default => true
    t.string   "heared_first_at",    :default => ".."
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token",                     :null => false
    t.string   "perishable_token",                      :null => false
    t.integer  "login_count",        :default => 0,     :null => false
    t.integer  "failed_login_count", :default => 0,     :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "openid_identifier"
    t.string   "phone_number"
    t.string   "group"
    t.string   "trackable",          :default => "0"
    t.boolean  "send_score",         :default => false
    t.boolean  "new_round"
  end

  add_index "users", ["trackable"], :name => "index_users_on_trackable"

end
