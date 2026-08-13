require 'etengine/scenario_migration'

class SimplifiedBuildingsHeatInputs < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # An insulation input of a group of buildings: the key of the old input, the key of the new one,
  # and the area attribute holding the typical heating demand of such a building, which is the
  # value the old input started from.
  Insulation = Struct.new(:old_key, :new_key, :demand_attribute) do
    # Converts the absolute input into its percentage equivalent.
    def migrate(scenario)
      # If the old input is not present, we don't need to do anything.
      return unless scenario.user_values.key?(old_key)

      # Without a typical demand there is nothing to compare the old value against,
      # so the old input is left as it is.
      default_demand = scenario.area[demand_attribute]
      return if default_demand.nil? || default_demand.zero?

      # The new input only expresses a reduction of the demand. A demand above the default is not
      # an insulation improvement and has nowhere to go, so it is left out.
      ratio = scenario.user_values.delete(old_key) / default_demand
      reduction = ((1.0 - ratio) * 100.0).round(INSULATION_DECIMALS)
      scenario.user_values[new_key] = reduction if reduction.positive?
    end
  end

  # Area attribute with the number of buildings standing in the area today.
  PRESENT_BUILDINGS_ATTRIBUTE = 'present_number_of_buildings'.freeze

  # The number of buildings built in the future year. An absolute count in both inputs.
  NEW_BUILDINGS_OLD_KEY = 'buildings_number_of_buildings_future'.freeze
  NEW_BUILDINGS_NEW_KEY = 'buildings_number_of_buildings_new'.freeze

  # The old input is the number of present buildings still standing in the future year,
  # the new input the number of them demolished. Both are absolute counts.
  DEMOLISHED_BUILDINGS_OLD_KEY = 'buildings_number_of_buildings_present'.freeze
  DEMOLISHED_BUILDINGS_NEW_KEY = 'buildings_number_of_buildings_demolished'.freeze

  # The insulation of the buildings built in the future year. The old input is their heating demand
  # in kWh/m2, the new input the reduction of that demand as a percentage, which can only be
  # positive.
  NEW_INSULATION = Insulation.new(
    old_key: 'buildings_insulation_level_buildings_future',
    new_key: 'buildings_insulation_new_buildings',
    demand_attribute: 'typical_useful_demand_for_space_heating_buildings_future'
  )

  # The same for the buildings already standing today.
  EXISTING_INSULATION = Insulation.new(
    old_key: 'buildings_insulation_level_buildings_present',
    new_key: 'buildings_insulation_existing_buildings',
    demand_attribute: 'typical_useful_demand_for_space_heating_buildings_present'
  )

  # The new inputs are written with the precision of their own step value:
  #  whole buildings, and tenths of a percent of demand.
  BUILDINGS_DECIMALS = 0
  INSULATION_DECIMALS = 1

  def up
    migrate_scenarios do |scenario|
      # Building stock (Present number of buildings is mandatory)
      present_buildings = present_buildings(scenario)
      next if present_buildings.nil? || present_buildings.zero?
      migrate_new_buildings(scenario)
      migrate_demolished(scenario, present_buildings)

      # Heat demand and insulation
      NEW_INSULATION.migrate(scenario)
      EXISTING_INSULATION.migrate(scenario)
    end
  end

  private

  def present_buildings(scenario)
    return nil unless Atlas::Dataset.exists?(scenario.area_code)

    buildings = scenario.area[PRESENT_BUILDINGS_ATTRIBUTE]

    # The area attribute holds the full-size region, while the user values of a scaled scenario are
    # in the units of its own smaller region, as is the area attribute once the graph is built.
    return buildings unless scenario.scaler && buildings

    scenario.scaler.scale(buildings)
  end

  def migrate_new_buildings(scenario)
    # If the old input is not present, no buildings were added.
    return unless scenario.user_values.key?(NEW_BUILDINGS_OLD_KEY)

    # Both inputs count buildings, so the number only moves to the new key.
    new_buildings = scenario.user_values.delete(NEW_BUILDINGS_OLD_KEY)
    scenario.user_values[NEW_BUILDINGS_NEW_KEY] = new_buildings.round(BUILDINGS_DECIMALS).to_f
  end

  def migrate_demolished(scenario, present_buildings)
    # If the old input is not present, nothing was demolished.
    return unless scenario.user_values.key?(DEMOLISHED_BUILDINGS_OLD_KEY)

    # The old input set the remaining buildings, so the demolished buildings are whatever is
    # missing from the present number of buildings.
    existing_buildings = [scenario.user_values.delete(DEMOLISHED_BUILDINGS_OLD_KEY), present_buildings].min
    scenario.user_values[DEMOLISHED_BUILDINGS_NEW_KEY] =
      (present_buildings - existing_buildings).round(BUILDINGS_DECIMALS).to_f
  end
end
