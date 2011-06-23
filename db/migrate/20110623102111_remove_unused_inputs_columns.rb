#  create_table "inputs", :force => true do |t|
#    t.string   "name"
#    t.string   "key"
#    t.text     "keys"
#    t.string   "attr_name"
#    t.integer  "slide_id"
#    t.string   "share_group"
#    t.string   "start_value_gql"
#    t.string   "min_value_gql"
#    t.string   "max_value_gql"
#    t.float    "min_value"
#    t.float    "max_value"
#    t.float    "start_value"
#    t.float    "order_by"
#    t.decimal  "step_value",                :precision => 4, :scale => 2
#    t.datetime "created_at"
#    t.datetime "updated_at"
#    t.string   "update_type"
#    t.string   "unit"
#    t.float    "factor"
#    t.string   "input_type"
#    t.string   "label"
#    t.text     "comments"
#    t.string   "update_value"
#    t.integer  "complexity",                                              :default => 1
#    t.string   "interface_group"
#    t.string   "update_max"
#    t.boolean  "locked_for_municipalities"
#    t.string   "label_query"
#  end

class RemoveUnusedInputsColumns < ActiveRecord::Migration
  def self.up
    remove_column :inputs, :complexity
    remove_column :inputs, :order_by
    remove_column :inputs, :step_value
    remove_column :inputs, :locked_for_municipalities
    remove_column :inputs, :slide_id
    remove_column :inputs, :interface_group
    remove_column :inputs, :update_max
    remove_column :inputs, :update_value
    remove_column :inputs, :input_type
  end

  def self.down
  end
end
