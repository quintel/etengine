class DropBlueprintLayouts < ActiveRecord::Migration
  def up
    drop_table :blueprint_layouts
    remove_column :converter_positions, :blueprint_layout_id
  end

  def down
    create_table "blueprint_layouts", :force => true do |t|
      t.string   "key"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_column :converter_positions, :blueprint_layout_id, :integer
    add_index :converter_positions, :blueprint_layout_id
  end
end
