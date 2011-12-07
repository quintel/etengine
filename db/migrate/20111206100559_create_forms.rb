class CreateForms < ActiveRecord::Migration
  def self.up
    create_table "input_tool_forms" do |t|
      t.string :area_code
      t.string :code
      t.text   :values
    end
  end

  def self.down
    drop_table :input_tool_forms
  end
end
