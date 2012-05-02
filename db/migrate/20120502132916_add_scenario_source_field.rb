class AddScenarioSourceField < ActiveRecord::Migration
  def change
    add_column :scenarios, :source, :string
    add_index :scenarios, :source
  end
end
