class RemovePageTitles < ActiveRecord::Migration
  def self.up
    drop_table :page_titles
  end

  def self.down
    create_table "page_titles", :force => true do |t|
      t.string   "controller"
      t.string   "action"
      t.string   "title"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
