class CreateUserCurves < ActiveRecord::Migration[7.0]
  def change
    create_table :user_curves, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
      t.integer :scenario_id, null: false
      t.string :key, null: false
      t.binary :curve, null: false # I think binary should avoid Messagepack encoding issues
      t.timestamps
    end

    add_index :user_curves, [:scenario_id, :key], unique: true
  end
end
