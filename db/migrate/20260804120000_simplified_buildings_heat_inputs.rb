require 'etengine/scenario_migration'

class SimplifiedBuildingsHeatInputs < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # An insulation input of a group of buildings: the key of the old input, the key of the new one,
  # and the area attribute holding the typical heating demand of such a building, which is the
  # value the old input started from.
  Insulation = Struct.new(:old_key, :new_key, :demand_attribute) do
    # Converts the absolute input into its percentage equivalent. Returns the demand of these
    # buildings as requested and as explained by insulation alone, which the behaviour conversion
    # needs as a weight.
    def migrate(scenario, buildings)
      default_demand = scenario.area[demand_attribute]
      return { insulated: 0.0, requested: 0.0 } if default_demand.nil? || default_demand.zero?

      requested_ratio = requested_ratio(scenario, default_demand)

      # Only the part of the demand below the default is an insulation improvement.
      insulated_ratio = [requested_ratio, 1.0].min
      scenario.user_values[new_key] = (insulated_ratio - 1.0) * 100.0 if insulated_ratio < 1.0

      demand = buildings * default_demand

      { insulated: demand * insulated_ratio, requested: demand * requested_ratio }
    end

    private

    # An untouched input keeps the default demand, but still weighs in the behaviour input as that
    # scales the demand of its buildings too.
    def requested_ratio(scenario, default_demand)
      return 1.0 unless scenario.user_values.key?(old_key)

      scenario.user_values.delete(old_key) / default_demand
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

  # The percentage change in space heating demand of all buildings at once (max 50%).
  BEHAVIOUR_KEY = 'buildings_space_heating_behaviour'.freeze
  BEHAVIOUR_MAX = 50.0

  # The insulation of the buildings built in the future year. The old input is their heating demand
  # in kWh/m2, the new input the reduction of that demand as a percentage, which can only be
  # negative.
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

  def up
    @clamped_scenario_ids = []

    migrate_scenarios do |scenario|
      # Building stock (Present number of buildings is mandatory)
      present_buildings = present_buildings(scenario)
      next if present_buildings.nil? || present_buildings.zero?
      new_buildings = migrate_new_buildings(scenario)
      existing_buildings = migrate_demolished(scenario, present_buildings)

      # Heat demand and insulation (informed by new and existing buildings)
      new_demand = NEW_INSULATION.migrate(scenario, new_buildings)
      existing_demand = EXISTING_INSULATION.migrate(scenario, existing_buildings)
      migrate_behaviour(scenario, new_demand, existing_demand)
    end

    # Report on scenarios that lost demand above the maximum behaviour (purely informational, not blocking).
    return if @clamped_scenario_ids.empty?

    say("#{@clamped_scenario_ids.length} scenarios asked for more than +#{BEHAVIOUR_MAX}% " \
        'behaviour and lost the demand above it')
    say(@clamped_scenario_ids.join(', '), true)
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
    return 0.0 unless scenario.user_values.key?(NEW_BUILDINGS_OLD_KEY)

    # Both inputs count buildings, so the number only moves to the new key.
    new_buildings = scenario.user_values.delete(NEW_BUILDINGS_OLD_KEY)
    scenario.user_values[NEW_BUILDINGS_NEW_KEY] = new_buildings

    # Returns the number of new buildings, which the insulation conversion needs as a weight.
    new_buildings
  end

  def migrate_demolished(scenario, present_buildings)
    # If the old input is not present, nothing was demolished.
    return present_buildings unless scenario.user_values.key?(DEMOLISHED_BUILDINGS_OLD_KEY)

    # The old input set the remaining buildings, so the demolished buildings are whatever is
    # missing from the present number of buildings.
    existing_buildings = [scenario.user_values.delete(DEMOLISHED_BUILDINGS_OLD_KEY), present_buildings].min
    scenario.user_values[DEMOLISHED_BUILDINGS_NEW_KEY] = present_buildings - existing_buildings

    # Returns the number of buildings left standing, which the insulation conversion needs as a weight.
    existing_buildings
  end

  # Demand left above the default is not an insulation improvement but a behavioural change. The
  # behaviour input scales the demand of all buildings at once, so both groups are weighted by the
  # demand they have left after insulation to keep the total demand the same.
  def migrate_behaviour(scenario, new_demand, existing_demand)
    insulated_demand = new_demand[:insulated] + existing_demand[:insulated]
    requested_demand = new_demand[:requested] + existing_demand[:requested]

    # Without any demand there is nothing left to account for.
    return if insulated_demand.zero?

    behaviour = (requested_demand / insulated_demand - 1.0) * 100.0

    # Behaviour can only add demand, so a non-positive result means there is nothing to record.
    return unless behaviour.positive?

    # The input reaches no further than its maximum, so the demand above it cannot be kept.
    if behaviour > BEHAVIOUR_MAX
      behaviour = BEHAVIOUR_MAX
      @clamped_scenario_ids << scenario.id
    end

    scenario.user_values[BEHAVIOUR_KEY] = behaviour
  end
end
