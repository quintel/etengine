class CreateScenarioAttachments < ActiveRecord::Migration[5.2]
  def change
    create_table :scenario_attachments do |t|
      t.references :scenario,
        type: :integer,
        index: true
      t.string  :attachment_key
      t.integer :other_scenario_id
      t.string  :other_scenario_title
      t.integer :other_end_year
      t.string  :other_dataset_key
      t.integer :other_saved_scenario_id
    end
  end
end
