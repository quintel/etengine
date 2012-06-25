class DropGqueriesTable < ActiveRecord::Migration
  def up
    drop_table :gqueries
  end

  def down
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
  end
end
