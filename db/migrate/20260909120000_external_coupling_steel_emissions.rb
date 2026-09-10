require 'etengine/scenario_migration'

# The steel external coupling node no longer derives its CO2 emissions from the carriers it
# consumes: a new input sets them directly, and the node emits nothing until it is given a value.
# Scenarios routing steel production through the node keep their emissions only if the amount the
# old model derived is written into that input.
class ExternalCouplingSteelEmissions < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # The share of steel production routed through the external coupling node, and the demand of the
  # steel sector relative to the start year. Both are percentages.
  COUPLING_SHARE_KEY = 'external_coupling_industry_metal_steel_external_coupling_share'.freeze
  TOTAL_DEMAND_KEY = 'external_coupling_industry_metal_steel_total_demand'.freeze

  # The efficiency with which the node turns its energetic input into steel, as a percentage.
  EFFICIENCY_KEY = 'external_coupling_industry_metal_steel_efficiency'.freeze

  # The new input, in Mton of CO2.
  EMISSIONS_KEY = 'external_coupling_industry_metal_steel_external_coupling_node_co2_emissions'.freeze

  # Every carrier the node used to emit CO2 for, with the emissions it carries in kg/MJ and the
  # share it takes of the node's energetic input by default, as a percentage. The three remaining
  # carriers the node consumes (electricity, hydrogen and steam_hot_water) emit nothing.
  Carrier = Struct.new(:name, :emission_factor, :default_share) do
    def share_key = "external_coupling_industry_metal_steel_energetic_#{name}_share"
  end

  CARRIERS = [
    Carrier.new(name: 'coal_gas', emission_factor: 0.0926835, default_share: 56.83),
    Carrier.new(name: 'cokes', emission_factor: 0.0926835, default_share: 0.08),
    Carrier.new(name: 'coal', emission_factor: 0.0945, default_share: 0.0),
    Carrier.new(name: 'crude_oil', emission_factor: 0.0733, default_share: 0.0),
    Carrier.new(name: 'network_gas', emission_factor: 0.0565, default_share: 23.77),
    Carrier.new(name: 'wood_pellets', emission_factor: 0.112, default_share: 0.0)
  ].freeze

  # The defaults of the inputs above. The external coupling node carries the same attributes in
  # every region, so its shares and its efficiency are the same everywhere too.
  DEFAULT_TOTAL_DEMAND = 100.0
  DEFAULT_EFFICIENCY = 13.98

  # The node whose demand the dump holds.
  STEEL_PRODUCTION_NODE = 'industry_steel_production'.freeze

  # The dump comes straight out of Atlas, which expresses energy demands in a unit a million times
  # larger than the MJ the emission factors above are per. ETEngine multiplies them by the same
  # factor when it imports a dataset.
  MJ_PER_DUMPED_UNIT = 1_000_000.0

  # The kg of CO2 in one Mton, the unit of the new input.
  KG_PER_MTON = 1_000_000_000.0

  # The new input is written with the precision of its own step value.
  EMISSIONS_DECIMALS = 1

  def up
    # The demand of the steel sector in the start year of each dataset, dumped with ETSource's
    # `rake refinery_dump`. Refinery derives it from the energy balance, so it is not an area
    # attribute the migration could read here.
    @start_year_production = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))

    # A scenario already holding the new input has had it set deliberately, and its value is not the
    # migration's to overwrite.
    migrate_scenarios do |scenario|
      next if scenario.user_values.key?(EMISSIONS_KEY)

      # Only the steel routed through the external coupling node emits anything here.
      coupling_share = input_value(scenario, COUPLING_SHARE_KEY, 0.0)
      next unless coupling_share.positive?

      next unless convertible_area?(scenario)
      next unless convertible_scaling?(scenario)

      # A node emitting nothing is what the new input already defaults to, so only a positive
      # amount is worth writing. An input rescaled for a differently-sized area may hold a NaN or
      # an infinity, which carries through the arithmetic into a value worth writing even less.
      emissions = emissions_of(scenario, coupling_share)
      scenario.user_values[EMISSIONS_KEY] = emissions if emissions.positive? && emissions.finite?
    end

    # Names every area the migration passed over, and how many scenarios it left behind there.
    print_report('Skipped scenarios of areas ETSource no longer holds:', retired_areas)
    print_report('Skipped scenarios of areas with no dumped production:', undumped_areas)
  end

  private

  # The areas the migration passed over, tallied per area code.
  def retired_areas = @retired_areas ||= Hash.new(0)
  def undumped_areas = @undumped_areas ||= Hash.new(0)

  # Scaling a scenario reads its area, which raises for an area ETSource no longer holds.
  # Also an area the dump does not cover has no start year production to convert.
  def convertible_area?(scenario)
    unless Atlas::Dataset.exists?(scenario.area_code)
      retired_areas[scenario.area_code] += 1
      return false
    end

    unless @start_year_production.key?(scenario.area_code)
      undumped_areas[scenario.area_code] += 1
      return false
    end

    true
  end

  # A scaled region without industry has its steel production zeroed by the graph, and a scaler
  # with a zero base value scales every area attribute to NaN or infinity. Check Industry first,
  # since reading the multiplier loads the whole area and is more costly.
  def convertible_scaling?(scenario)
    scaler = scenario.scaler
    return true unless scaler
    return false unless scaler.has_industry?

    # A base value is missing for an area attribute no dataset defines, and zero for an empty
    # region. Neither can be divided by.
    scaler.base_value.to_f.positive? && scaler.multiplier.finite?
  end

  def print_report(heading, areas)
    return if areas.empty?

    say(heading)

    areas.sort.each do |area_code, scenarios|
      say("#{scenarios} #{'scenario'.pluralize(scenarios)} from #{area_code}", true)
    end
  end

  # An input of a share group may hold its value as a balanced value rather than a user value, and
  # an input the user never touched keeps its default.
  def input_value(scenario, key, default)
    (scenario.user_values[key] || scenario.balanced_values[key] || default).to_f
  end

  # The CO2 the external coupling node emitted in the future year, in Mton.
  def emissions_of(scenario, coupling_share)
    # The steel the node produces, in MJ: the production of the whole sector in the start year,
    # grown to the future year, of which the node takes its share.
    steel_output = start_year_production(scenario) *
      (input_value(scenario, TOTAL_DEMAND_KEY, DEFAULT_TOTAL_DEMAND) / 100.0) *
      (coupling_share / 100.0)

    # A node producing steel out of nothing consumes nothing and emits nothing.
    output_efficiency = input_value(scenario, EFFICIENCY_KEY, DEFAULT_EFFICIENCY) / 100.0
    return 0.0 unless output_efficiency.positive?

    # The energy the node consumed to produce that steel, and the emissions of every carrier it
    # took its share of that energy from.
    energetic_input = steel_output / output_efficiency

    total_emissions = CARRIERS.sum do |carrier|
      share = input_value(scenario, carrier.share_key, carrier.default_share)
      energetic_input * (share / 100.0) * carrier.emission_factor
    end

    (total_emissions / KG_PER_MTON).round(EMISSIONS_DECIMALS)
  end

  # The production of the steel sector in the start year, in MJ. The dump holds the production of
  # the full-size region, while the user values of a scaled scenario are in the units of its own
  # smaller region.
  def start_year_production(scenario)
    production = @start_year_production[scenario.area_code][STEEL_PRODUCTION_NODE].to_f * MJ_PER_DUMPED_UNIT
    return production unless scenario.scaler

    scenario.scaler.scale(production)
  end
end
