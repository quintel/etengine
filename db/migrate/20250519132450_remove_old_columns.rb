class RemoveOldColumns < ActiveRecord::Migration[7.1]
  def change
    remove_column :forecast_storage_orders, :order_old, :text
    remove_column :heat_network_orders, :order_old, :text
    remove_column :households_space_heating_producer_orders, :order_old, :text
    remove_column :hydrogen_demand_orders, :order_old, :text
    remove_column :hydrogen_supply_orders, :order_old, :text

    remove_column :scenarios, :balanced_values_old, :text, size: :medium
    remove_column :scenarios, :metadata_old, :text, size: :medium
    remove_column :scenarios, :active_couplings_old, :text, size: :medium
  end
end
