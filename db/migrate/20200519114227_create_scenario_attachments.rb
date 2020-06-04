class CreateScenarioAttachments < ActiveRecord::Migration[5.2]
  def change
    create_table :scenario_attachments do |t|
      t.references :scenario,
        type: :integer,
        index: true
      t.string  :key
      t.integer :source_scenario_id
      t.string  :source_scenario_title
      t.integer :source_end_year
      t.string  :source_dataset_key
      t.integer :source_saved_scenario_id

      t.index [:scenario_id, :key], unique: true
    end
  end
end
