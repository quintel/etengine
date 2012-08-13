class DropOldBlueprintModelTable < ActiveRecord::Migration
  def up
    drop_table :blueprint_models
  end

  def down
    create_table "blueprint_models", :force => true do |t|
      t.string   "title"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
