class AddTemperatureToHeatNetworkOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :heat_network_orders, :temperature, :string, default: "mt"

    # Add new unique index
    add_index :heat_network_orders, [:scenario_id, :temperature], unique: true

    # Remove uniqueness from index on scenarios - I can't find a better way than just doing it again
    remove_index :heat_network_orders, :scenario_id
    add_index :heat_network_orders, :scenario_id
  end
end
