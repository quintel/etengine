class CreateUserCurves < ActiveRecord::Migration[7.0]
  def change
    create_table :user_curves, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
      t.integer :scenario_id, null: false
      t.string  :key, null: false
      t.string  :name

      # MEDIUMBLOB - I tested a curve serialized with MessagePack and it was ~70 kb.
      # A normal blob is 64 kb. So we need a medium blob
      t.binary  :curve, null: false, limit: 16.megabytes - 1

      # Metadata fields
      t.integer :source_scenario_id
      t.string  :source_scenario_title
      t.integer :source_saved_scenario_id
      t.string  :source_dataset_key
      t.integer :source_end_year

      t.timestamps
    end

    add_index :user_curves, [:scenario_id, :key], unique: true
  end
end
