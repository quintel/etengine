class CreateScenarioScalings < ActiveRecord::Migration
  def change
    create_table :scenario_scalings do |t|
      t.belongs_to :scenario
      t.string     :area_attribute
      t.float      :value
    end

    add_index :scenario_scalings, :scenario_id, unique: true
  end
end
