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

ActiveRecord::Schema.define(:version => 20111124155441) do

  create_table "areas", :force => true do |t|
    t.string   "country"
    t.float    "co2_price"
    t.float    "co2_percentage_free"
    t.float    "el_import_capacity"
    t.float    "el_export_capacity"
    t.float    "co2_emission_1990"
    t.float    "co2_emission_2009"
    t.float    "co2_emission_electricity_1990"
    t.float    "roof_surface_available_pv"
    t.float    "coast_line"
    t.float    "offshore_suitable_for_wind"
    t.float    "onshore_suitable_for_wind"
    t.float    "areable_land"
    t.float    "available_land"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "land_available_for_solar"
    t.float    "km_per_car"
    t.float    "import_electricity_primary_demand_factor",              :default => 1.82
    t.float    "export_electricity_primary_demand_factor",              :default => 1.0
    t.float    "capacity_buffer_in_mj_s"
    t.float    "capacity_buffer_decentral_in_mj_s"
    t.float    "km_per_truck"
    t.float    "annual_infrastructure_cost_electricity"
    t.float    "number_households"
    t.float    "number_inhabitants"
    t.boolean  "use_network_calculations"
    t.boolean  "has_coastline"
    t.boolean  "has_mountains"
    t.boolean  "has_lignite"
    t.float    "annual_infrastructure_cost_gas"
    t.string   "entity"
    t.float    "percentage_of_new_houses"
    t.float    "recirculation"
    t.float    "heat_recovery"
    t.float    "ventilation_rate"
    t.float    "market_share_daylight_control"
    t.float    "market_share_motion_detection"
    t.float    "buildings_heating_share_offices"
    t.float    "buildings_heating_share_schools"
    t.float    "buildings_heating_share_other"
    t.float    "roof_surface_available_pv_buildings"
    t.float    "insulation_level_existing_houses"
    t.float    "insulation_level_new_houses"
    t.float    "insulation_level_schools"
    t.float    "insulation_level_offices"
    t.boolean  "has_buildings"
    t.boolean  "has_agriculture",                                       :default => true
    t.integer  "current_electricity_demand_in_mj",         :limit => 8, :default => 1
    t.boolean  "has_solar_csp"
    t.boolean  "has_old_technologies"
    t.integer  "parent_id"
    t.boolean  "has_cold_network"
    t.float    "cold_network_potential"
    t.boolean  "has_heat_import"
    t.boolean  "has_industry"
    t.boolean  "has_other"
    t.boolean  "has_fce"
    t.text     "input_values"
  end

  add_index "areas", ["parent_id"], :name => "index_areas_on_parent_id"

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

  create_table "blueprints", :force => true do |t|
    t.string   "name"
    t.string   "graph_version"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "blueprint_model_id"
  end

  add_index "blueprints", ["blueprint_model_id"], :name => "index_blueprints_on_blueprint_model_id"

  create_table "blueprints_converters", :id => false, :force => true do |t|
    t.integer "converter_id"
    t.integer "blueprint_id"
  end

  add_index "blueprints_converters", ["blueprint_id"], :name => "index_blueprints_converters_on_blueprint_id"
  add_index "blueprints_converters", ["converter_id", "blueprint_id"], :name => "index_blueprints_converters_on_converter_id_and_blueprint_id"

  create_table "carriers", :force => true do |t|
    t.integer  "carrier_id"
    t.string   "key"
    t.string   "name"
    t.boolean  "infinite"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "carrier_color"
  end

  add_index "carriers", ["carrier_id"], :name => "index_carriers_on_carrier_id"
  add_index "carriers", ["key"], :name => "index_carriers_on_key"

  create_table "converter_positions", :force => true do |t|
    t.integer  "converter_id"
    t.integer  "x"
    t.integer  "y"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hidden"
    t.integer  "blueprint_layout_id"
  end

  add_index "converter_positions", ["converter_id"], :name => "index_converter_positions_on_converter_id"

  create_table "converters", :force => true do |t|
    t.integer  "converter_id"
    t.string   "key"
    t.string   "name"
    t.integer  "use_id"
    t.integer  "sector_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "energy_balance_group_id"
  end

  create_table "converters_groups", :id => false, :force => true do |t|
    t.integer "converter_id"
    t.integer "group_id"
  end

  add_index "converters_groups", ["converter_id", "group_id"], :name => "index_converters_groups_on_converter_id_and_group_id"

  create_table "dataset_carrier_data", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "carrier_id"
    t.float    "cost_per_mj"
    t.float    "co2_conversion_per_mj"
    t.float    "sustainable"
    t.float    "typical_production_per_km2"
    t.integer  "area_id"
    t.float    "kg_per_liter"
    t.float    "mj_per_kg"
    t.float    "co2_exploration_per_mj",                     :default => 0.0
    t.float    "co2_extraction_per_mj",                      :default => 0.0
    t.float    "co2_treatment_per_mj",                       :default => 0.0
    t.float    "co2_transportation_per_mj",                  :default => 0.0
    t.float    "co2_waste_treatment_per_mj",                 :default => 0.0
    t.float    "supply_chain_margin_per_mj"
    t.float    "oil_price_correlated_part_production_costs"
  end

  add_index "dataset_carrier_data", ["carrier_id"], :name => "index_dataset_carrier_data_on_carrier_id"

  create_table "dataset_converter_data", :force => true do |t|
    t.string   "name"
    t.integer  "preset_demand",                                              :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "dataset_id"
    t.integer  "converter_id"
    t.integer  "demand_expected_value",                                      :limit => 8
    t.float    "network_capacity_available_in_mw"
    t.float    "network_capacity_used_in_mw"
    t.float    "land_use_per_unit"
    t.float    "technical_lifetime"
    t.float    "lead_time"
    t.float    "construction_time"
    t.float    "costs_per_mj"
    t.float    "network_expansion_costs_in_euro_per_mw"
    t.integer  "use_id"
    t.integer  "sector_id"
    t.string   "key"
    t.float    "wacc"
    t.float    "capacity_factor"
    t.float    "co2_free"
    t.float    "simult_wd"
    t.float    "simult_sd"
    t.float    "simult_we"
    t.float    "simult_se"
    t.float    "peak_load_units_present"
    t.float    "full_load_hours"
    t.float    "operation_and_maintenance_cost_fixed_per_mw_input"
    t.float    "operation_and_maintenance_cost_variable_per_full_load_hour"
    t.integer  "municipality_demand",                                        :limit => 8
    t.float    "typical_nominal_input_capacity"
    t.float    "residual_value_per_mw_input"
    t.float    "decommissioning_costs_per_mw_input"
    t.float    "purchase_price_per_mw_input"
    t.float    "installing_costs_per_mw_input"
    t.float    "part_ets"
    t.float    "ccs_investment_per_mw_input"
    t.float    "ccs_operation_and_maintenance_cost_per_full_load_hour"
    t.float    "decrease_in_nomimal_capacity_over_lifetime"
    t.float    "availability"
    t.float    "variability"
  end

  add_index "dataset_converter_data", ["converter_id"], :name => "index_dataset_converter_data_on_converter_id"
  add_index "dataset_converter_data", ["dataset_id"], :name => "index_converter_datas_on_graph_data_id"

  create_table "dataset_link_data", :force => true do |t|
    t.integer  "link_type",               :default => 0
    t.float    "share"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "dataset_id"
    t.integer  "link_id"
    t.integer  "max_demand", :limit => 8
  end

  add_index "dataset_link_data", ["dataset_id"], :name => "index_link_datas_on_graph_data_id"
  add_index "dataset_link_data", ["link_id"], :name => "index_dataset_link_data_on_link_id"

  create_table "dataset_slot_data", :force => true do |t|
    t.integer "dataset_id"
    t.integer "slot_id"
    t.float   "conversion"
    t.boolean "dynamic"
  end

  add_index "dataset_slot_data", ["dataset_id"], :name => "index_slot_datas_on_graph_data_id"
  add_index "dataset_slot_data", ["slot_id"], :name => "index_dataset_slot_data_on_slot_id"

  create_table "datasets", :force => true do |t|
    t.integer  "blueprint_id"
    t.string   "region_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "area_id"
  end

  add_index "datasets", ["region_code"], :name => "index_graph_datas_on_region_code"

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

  create_table "gql_test_cases", :force => true do |t|
    t.string   "name"
    t.text     "instruction", :limit => 2147483647
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "settings",    :limit => 2147483647
    t.text     "inputs",      :limit => 2147483647
  end

  create_table "gqueries", :force => true do |t|
    t.string   "key"
    t.text     "query"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "not_cacheable",   :default => false
    t.string   "unit"
    t.string   "deprecated_key"
    t.integer  "gquery_group_id"
  end

  add_index "gqueries", ["gquery_group_id"], :name => "index_gqueries_on_gquery_group_id"
  add_index "gqueries", ["key"], :name => "index_gqueries_on_key"

  create_table "gquery_groups", :force => true do |t|
    t.string   "group_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  create_table "graphs", :force => true do |t|
    t.integer  "blueprint_id"
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "graphs", ["blueprint_id"], :name => "index_graphs_on_blueprint_id"
  add_index "graphs", ["dataset_id"], :name => "index_user_graphs_on_graph_data_id"

  create_table "groups", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key"
    t.string   "shortcut"
    t.integer  "group_id"
  end

  add_index "groups", ["group_id"], :name => "index_groups_on_group_id"

  create_table "historic_serie_entries", :force => true do |t|
    t.integer  "historic_serie_id"
    t.integer  "year"
    t.float    "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "historic_serie_entries", ["historic_serie_id"], :name => "index_historic_serie_entries_on_historic_serie_id"

  create_table "historic_series", :force => true do |t|
    t.string   "key"
    t.string   "area_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "inputs", :force => true do |t|
    t.string   "name"
    t.string   "key"
    t.text     "keys"
    t.string   "attr_name"
    t.string   "share_group"
    t.string   "start_value_gql"
    t.string   "min_value_gql"
    t.string   "max_value_gql"
    t.float    "min_value"
    t.float    "max_value"
    t.float    "start_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "update_type"
    t.string   "unit"
    t.float    "factor"
    t.string   "label"
    t.text     "comments"
    t.string   "label_query"
    t.string   "updateable_period", :default => "future", :null => false
    t.text     "query"
    t.string   "v1_legacy_unit"
  end

  add_index "inputs", ["key"], :name => "unique api key", :unique => true

  create_table "links", :force => true do |t|
    t.integer "blueprint_id"
    t.integer "parent_id"
    t.integer "child_id"
    t.integer "carrier_id"
    t.integer "link_type"
    t.integer "country_specific"
  end

  add_index "links", ["blueprint_id"], :name => "index_links_on_blueprint_id"
  add_index "links", ["carrier_id"], :name => "index_links_on_carrier_id"
  add_index "links", ["child_id"], :name => "index_links_on_child_id"
  add_index "links", ["parent_id"], :name => "index_links_on_parent_id"

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
    t.text     "user_updates"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "user_values"
    t.integer  "end_year",           :default => 2040
    t.string   "country"
    t.boolean  "in_start_menu"
    t.string   "region"
    t.integer  "user_id"
    t.integer  "complexity",         :default => 3
    t.string   "scenario_type"
    t.integer  "preset_scenario_id"
    t.string   "type"
    t.boolean  "use_fce"
    t.datetime "present_updated_at"
    t.boolean  "protected"
  end

  add_index "scenarios", ["in_start_menu"], :name => "index_scenarios_on_in_start_menu"
  add_index "scenarios", ["protected"], :name => "index_scenarios_on_protected"
  add_index "scenarios", ["user_id"], :name => "index_scenarios_on_user_id"

  create_table "slots", :force => true do |t|
    t.integer "blueprint_id"
    t.integer "converter_id"
    t.integer "carrier_id"
    t.integer "direction"
    t.integer "country_specific"
  end

  add_index "slots", ["blueprint_id"], :name => "index_slots_on_blueprint_id"
  add_index "slots", ["carrier_id"], :name => "index_slots_on_carrier_id"
  add_index "slots", ["converter_id"], :name => "index_slots_on_converter_id"

  create_table "time_curve_entries", :force => true do |t|
    t.integer  "graph_id"
    t.integer  "converter_id"
    t.integer  "year"
    t.float    "value"
    t.string   "value_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "time_curve_entries", ["graph_id"], :name => "index_time_curve_entries_on_graph_id"

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

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

  create_table "year_values", :force => true do |t|
    t.integer  "year"
    t.float    "value"
    t.text     "description"
    t.integer  "value_by_year_id"
    t.string   "value_by_year_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "year_values", ["value_by_year_id", "value_by_year_type"], :name => "index_year_values_on_value_by_year_id_and_value_by_year_type"

end
