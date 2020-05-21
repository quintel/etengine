require 'etengine/scenario_migration'

class UpdateInterconnectorInputNames < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  INPUTS = {
    interconnectors_interconnector_capacity: :electricity_interconnector_1_capacity,
    interconnectors_availability_for_import: :electricity_interconnector_1_import_availability,
    interconnectors_availability_for_export: :electricity_interconnector_1_export_availability,
    costs_imported_electricity: :electricity_interconnector_1_marginal_costs,
    co2_emissions_of_imported_electricity_present: :electricity_interconnector_1_co2_emissions_present,
    co2_emissions_of_imported_electricity_future: :electricity_interconnector_1_co2_emissions_future
  }

  def up
    migrate_scenarios do |scenario|
      update_scenario(scenario, INPUTS)
    end
  end

  def down
    inverted_inputs = INPUTS.invert

    migrate_scenarios do |scenario|
      update_scenario(scenario, inverted_inputs)
    end
  end

  private

  def update_scenario(scenario, inputs)
    inputs.each do |from, to|
      next unless scenario.user_values.key?(from)

      scenario.user_values[to] = scenario.user_values.delete(from)
    end
  end
end
