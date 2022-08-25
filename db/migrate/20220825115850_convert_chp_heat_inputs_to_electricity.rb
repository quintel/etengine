# frozen_string_literal: true

require 'etengine/scenario_migration'

# Updates various industry capacity input values to set electricity output rather than heat output.
#
# See https://github.com/quintel/etsource/issues/2716
class ConvertChpHeatInputsToElectricity < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  INPUTS = {
    capacity_of_industry_chp_combined_cycle_gas_power_fuelmix:
      :industry_chp_combined_cycle_gas_power_fuelmix,
    capacity_of_industry_chp_engine_gas_power_fuelmix:
      :industry_chp_engine_gas_power_fuelmix,
    capacity_of_industry_chp_turbine_gas_power_fuelmix:
      :industry_chp_turbine_gas_power_fuelmix,
    capacity_of_industry_chp_ultra_supercritical_coal:
      :industry_chp_ultra_supercritical_coal,
    capacity_of_industry_chp_wood_pellets:
      :industry_chp_wood_pellets
  }

  def up
    migrate_scenarios do |scenario|
      INPUTS.each do |input, node|
        value = scenario.user_values[input]

        next if value.nil? || !value.is_a?(Numeric) || value.zero?

        scenario.user_values[input] = relative_efficiency(scenario.area_code, input) * value
      end
    end
  end

  private

  # Internal: Returns the relative efficiency (electricity / heat) for the node which is updated by
  # the given input key.
  #
  # If there are values in the cache, they will be read. Otherwise, we calculate values for all the
  # inputs/nodes and store them in the cache for use by other scenarios.
  def relative_efficiency(dataset, input)
    @values_cache ||= {}
    @values_cache[dataset] ||= create_values(dataset)

    @values_cache[dataset][input]
  end

  def create_values(dataset)
    say("Calculating values for #{dataset}", :subitem)

    graph = Scenario.default(area_code: dataset).gql.present.graph

    INPUTS.each_with_object({}) do |(input, node), hash|
      node = graph.node(node).query

      hash[input] = (
        node.query.electricity_output_conversion / #
        node.query.steam_hot_water_output_conversion
      )
    end
  end
end
