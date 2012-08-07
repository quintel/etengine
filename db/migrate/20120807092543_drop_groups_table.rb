class DropGroupsTable < ActiveRecord::Migration
  def up
    drop_table :groups
  end

  def down
    create_table "groups", :force => true do |t|
      t.string   "title"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "key"
      t.string   "shortcut"
      t.integer  "group_id"
    end

    add_index "groups", ["group_id"], :name => "index_groups_on_group_id"
  end
end
