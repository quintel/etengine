class RemoveAreaDependencies < ActiveRecord::Migration
  def self.up
    drop_table :area_dependencies    
  end

  def self.down
    create_table "area_dependencies", :force => true do |t|
      t.string  "dependent_on"
      t.text    "description"
      t.integer "dependent_on"
      t.string  "dependable_type"
    end
  end
end