class AddCoalGasDistribution < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  FINAL_DEMAND_SHARE_KEY = 'external_coupling_energy_distribution_coal_gas_final_demand_share'.freeze
  ENERGY_PRODUCTION_SHARE_KEY = 'external_coupling_energy_distribution_coal_gas_energy_production_share'.freeze
  CHEMICAL_FEEDSTOCK_SHARE_KEY = 'external_coupling_energy_distribution_coal_gas_chemical_feedstock_share'.freeze

  def up
    migrate_scenarios do |scenario|
      next unless scenario.user_values.key?(ENERGY_PRODUCTION_SHARE_KEY && CHEMICAL_FEEDSTOCK_SHARE_KEY)

      energy_production_share = scenario.user_values[ENERGY_PRODUCTION_SHARE_KEY]
      chemical_feedstock_share = scenario.user_values[CHEMICAL_FEEDSTOCK_SHARE_KEY]

      next unless energy_production_share + chemical_feedstock_share < 100.0

      scenario.user_values[FINAL_DEMAND_SHARE_KEY] = 100.0 - chemical_feedstock_share - energy_production_share
    end
  end
end
