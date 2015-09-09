class AddBaseValueToScenarioScalings < ActiveRecord::Migration
  def change
    add_column :scenario_scalings, :base_value, :float, after: :value
  end
end
