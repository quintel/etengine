class DropDescriptions < ActiveRecord::Migration
  def self.up
    drop_table :descriptions
  end

  def self.down
    create_table "descriptions", :force => true do |t|
      t.text     "content_en"
      t.text     "short_content_en"
      t.integer  "describable_id"
      t.string   "describable_type"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "content_nl"
      t.text     "short_content_nl"
    end

    add_index "descriptions", ["describable_id", "describable_type"], :name => "index_descriptions_on_describable_id_and_describable_type"    
  end
end
