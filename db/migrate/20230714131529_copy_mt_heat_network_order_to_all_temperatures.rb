require 'etengine/scenario_migration'

class CopyMtHeatNetworkOrderToAllTemperatures < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  def up

    migrate_scenarios do |scenario|
      next if scenario.heat_network_orders.blank?


      # In the last migration we set the default temperature level to MT
      # So each scenario that already had a custom order set, now has it only for MT
      # In this migration we copy their custom order to the HT and LT networks as well
      standard_order = scenario.heat_network_order(:mt)
      scenario.heat_network_orders << HeatNetworkOrder.new(order: standard_order.order, temperature: :ht)
      scenario.heat_network_orders << HeatNetworkOrder.new(order: standard_order.order, temperature: :lt)

      scenario.save(validate: false, touch: false)
    end
  end
end
