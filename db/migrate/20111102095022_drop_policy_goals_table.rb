class DropPolicyGoalsTable < ActiveRecord::Migration
  def self.up
    drop_table :policy_goals
  end

  def self.down
    create_table "policy_goals", :force => true do |t|
      t.string   "key"
      t.string   "name"
      t.string   "query"
      t.string   "start_value_query"
      t.string   "unit"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "display_format"
      t.string   "reached_query"
    end

    add_index "policy_goals", ["key"], :name => "index_policy_goals_on_key"
    
  end
end
