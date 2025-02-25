class CreateScenarioVersionTags < ActiveRecord::Migration[7.0]
  def change
    create_table :scenario_version_tags do |t|
      t.integer :scenario_id, null: false
      t.integer :user_id, null: false
      t.text :description
      t.index ['scenario_id', 'user_id'], unique: true
    end
  end
end
