class AddCoalGasDistribution < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  FINAL_DEMAND_SHARE_KEY = 'external_coupling_energy_distribution_coal_gas_final_demand_share'.freeze
  ENERGY_PRODUCTION_SHARE_KEY = 'external_coupling_energy_distribution_coal_gas_energy_production_share'.freeze
  CHEMICAL_FEEDSTOCK_SHARE_KEY = 'external_coupling_energy_distribution_coal_gas_chemical_feedstock_share'.freeze

  def up
    migrate_scenarios do |scenario|
      next unless scenario.user_values.key?(ENERGY_PRODUCTION_SHARE_KEY || CHEMICAL_FEEDSTOCK_SHARE_KEY)

      energy_production_share = scenario.user_values[ENERGY_PRODUCTION_SHARE_KEY] || 0.0
      chemical_feedstock_share = scenario.user_values[CHEMICAL_FEEDSTOCK_SHARE_KEY] || 0.0
      final_demand_share = 100.0 - chemical_feedstock_share - energy_production_share

      if final_demand_share >= 100.0 || final_demand_share <= 0.01
        raise "Invalid final demand share: #{final_demand_share}. It must be between 0 and 100."
      else
        scenario.user_values[FINAL_DEMAND_SHARE_KEY] = final_demand_share
      end
    end
  end
end
