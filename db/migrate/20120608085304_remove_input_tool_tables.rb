class RemoveInputToolTables < ActiveRecord::Migration
  def up
    drop_table :input_tool_forms
  end

  def down
    create_table "input_tool_forms", :force => true do |t|
      t.string   "area_code"
      t.string   "code"
      t.text     "values"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
