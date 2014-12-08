class AddHasEnergyToScalings < ActiveRecord::Migration
  def change
    add_column :scenario_scalings, :has_energy, :boolean, null: false, default: true
  end
end
