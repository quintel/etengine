class DropRoundsTable < ActiveRecord::Migration
  def self.up
    drop_table :rounds
  end

  def self.down
    create_table "rounds", :force => true do |t|
      t.string   "name"
      t.boolean  "active"
      t.integer  "position"
      t.integer  "value"
      t.integer  "policy_goal_id"
      t.boolean  "completed"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
