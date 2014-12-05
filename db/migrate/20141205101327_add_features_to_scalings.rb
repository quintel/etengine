class AddFeaturesToScalings < ActiveRecord::Migration
  def change
    add_column :scenario_scalings, :has_agriculture, :boolean, null: false, default: false
    add_column :scenario_scalings, :has_industry,    :boolean, null: false, default: false
  end
end
