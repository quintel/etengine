class CreateScenarioAttachments < ActiveRecord::Migration[5.2]
  def change
    create_table :scenario_attachments do |t|
      t.references :scenario,
        type: :integer,
        index: true,
        foreign_key: true,
        null: false
      t.string  :key, null: false
      t.integer :source_scenario_id
      t.string  :source_scenario_title
      t.integer :source_end_year
      t.string  :source_dataset_key
      t.integer :source_saved_scenario_id

      t.foreign_key :scenarios,
        column: :source_scenario_id,
        name: 'index_scenario_attachments_on_source_scenario_id'

      t.index [:scenario_id, :key], unique: true
    end
  end
end
