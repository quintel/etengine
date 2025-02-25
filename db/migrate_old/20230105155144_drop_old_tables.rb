class DropOldTables < ActiveRecord::Migration[7.0]
  def change
    drop_table "fce_values", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

    drop_table "gquery_groups", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
      t.string "group_key"
      t.datetime "created_at", precision: nil
      t.datetime "updated_at", precision: nil
      t.text "description"
    end

    drop_table "query_table_cells", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
      t.integer "query_table_id"
      t.integer "row"
      t.integer "column"
      t.string "name"
      t.text "gquery"
      t.datetime "created_at", precision: nil
      t.datetime "updated_at", precision: nil
      t.index ["query_table_id"], name: "index_query_table_cells_on_query_table_id"
    end

    drop_table "query_tables", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
      t.string "name"
      t.text "description"
      t.integer "row_count"
      t.integer "column_count"
      t.datetime "created_at", precision: nil
      t.datetime "updated_at", precision: nil
    end

    drop_table "roles", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
      t.string "name"
      t.datetime "created_at", precision: nil
      t.datetime "updated_at", precision: nil
    end
  end
end
