require 'etengine/scenario_migration'

class SimplifiedHouseholdsHeatInputs < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # A construction period of the housing stock. The old inputs exist for every housing type, the new
  # ones cover all types of the period at once.
  Period = Struct.new(:name, :insulation_key) do
    def demolished_key = "households_demolished_#{name}"
    def residences_key(type) = "households_number_of_#{type}_#{name}"
    def insulation_level_key(type) = "households_insulation_level_#{type}_#{name}"
    def present_attribute(type) = "present_number_of_#{type}_#{name}"
    def demand_attribute(type) = "typical_useful_demand_for_space_heating_#{type}_#{name}"
    def demand_node(type) = "households_useful_demand_for_space_heating_#{type}_#{name}"
  end

  HOUSING_TYPES = %w[apartments detached_houses semi_detached_houses terraced_houses].freeze

  # The periods of the residences standing today. The old input is the number of them left standing in
  # the future year, the new input the number demolished. Both are absolute counts.
  EXISTING_PERIODS = %w[before_1945 1945_1964 1965_1984 1985_2004 2005_present].map do |name|
    Period.new(name: name, insulation_key: "households_insulation_#{name}")
  end.freeze

  # Residences built in the future year. They are not demolished, and their insulation input carries a
  # name of its own.
  NEW_PERIOD = Period.new(name: 'future', insulation_key: 'households_insulation_new_residences').freeze

  ALL_PERIODS = (EXISTING_PERIODS + [NEW_PERIOD]).freeze

  # The total number of residences built in the future year, an absolute count in both designs. The
  # new input holds at most as many new residences as the area has today.
  NEW_RESIDENCES_KEY = 'households_number_of_residences_new'.freeze
  PRESENT_RESIDENCES_ATTRIBUTE = 'present_number_of_residences'.freeze

  # The share each housing type takes of those new residences. The four belong to one share group.
  SHARE_KEYS = {
    'apartments' => 'households_share_of_apartments',
    'detached_houses' => 'households_share_of_detached',
    'semi_detached_houses' => 'households_share_of_semi_detached',
    'terraced_houses' => 'households_share_of_terraced'
  }.freeze

  # The floor area of a residence of each type in m2. No dataset attribute holds these; etsource
  # keeps them as literals in households_number_of_residences_new.ad, the same for every region.
  FLOOR_AREAS = {
    'apartments' => 84.0916691776263,
    'detached_houses' => 224.001485938283,
    'semi_detached_houses' => 147.709471392282,
    'terraced_houses' => 130.419159051538
  }.freeze

  # The new inputs are written with the precision of their own step value: whole residences, and
  # tenths of a percent. Residences are floored rather than rounded, since a scaled area holds a
  # fractional stock and rounding up could land above the maximum of the input.
  RESIDENCE_SHARE_DECIMALS = 1
  INSULATION_DECIMALS = 1

  def up
    # The heat demand of every housing type and period in the start year, dumped from the graph of
    # each dataset. The demand of the residences standing today is not an area attribute: the graph
    # derives it, so the insulation conversion cannot recalculate it here.
    @start_year_demands = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))

    # Scenarios already holding the new inputs are left untouched, so a repeated run changes nothing.
    migrate_scenarios(raise_if_no_changes: false) do |scenario|
      # The present housing stock is mandatory for the conversions ahead.
      next unless Atlas::Dataset.exists?(scenario.area_code)
      next unless @start_year_demands.key?(scenario.area_code)

      # A user value may hold a NaN, left by rescaling an input for a differently-sized area, and a
      # scaler with a zero base value scales every area attribute to NaN or infinity. Neither
      # leaves anything to convert, and neither scenario can be calculated, so both are skipped.
      next if scenario.user_values.any? { |_, value| value.is_a?(Float) && !value.finite? }
      next if scenario.scaler && !scenario.scaler.multiplier.finite?

      # Both conversions return the number of residences of every type and period,
      # which the insulation conversion will use to weight its housing types.
      residences = migrate_new_residences(scenario)
      residences.merge!(migrate_demolished(scenario))

      migrate_insulation(scenario, residences)
    end
  end

  private

  def present_residences(scenario, attribute)
    residences = scenario.area[attribute].to_f

    # The area attribute holds the full-size region, while the user values of a scaled scenario are in
    # the units of its own smaller region, as is the area attribute once the graph is built.
    return residences unless scenario.scaler

    scenario.scaler.scale(residences)
  end

  # Migrates the new residences and returns the number of new residences per type and period, which
  # the insulation conversion needs as a weight. There is only one period here: future.
  def migrate_new_residences(scenario)
    residences = {}
    touched = false

    HOUSING_TYPES.each do |type|
      built = scenario.user_values.delete(NEW_PERIOD.residences_key(type))
      touched ||= !built.nil?
      residences[type] = built.to_f
    end

    # If none of the old inputs is present, no residences were built.
    if touched
      built = residences.values.sum

      # Each old input allowed as many new residences as the area holds today, so the four together
      # allowed four times what the new input does. Anything above its maximum is dropped, and the
      # housing types keep the mix the user asked for.
      total = [built, present_residences(scenario, PRESENT_RESIDENCES_ATTRIBUTE)].min
      residences.transform_values! { |of_type| of_type * total / built } if total < built

      scenario.user_values[NEW_RESIDENCES_KEY] = total.floor.to_f
      migrate_new_residences_shares(scenario, residences, total) if total.positive?
    end

    residences.transform_keys { |type| [type, NEW_PERIOD.name] }
  end

  # The four shares belong to a share group and have to sum to 100 exactly. Three are written as user
  # values and the largest is left to the balancer as a balanced value, which is the state the
  # application itself keeps when a user sets three of the four sliders. The largest is the one the
  # balancer can move furthest: it takes the rounding of the other three without falling below zero,
  # and it has room left to absorb whatever the user changes next.
  def migrate_new_residences_shares(scenario, residences, total)
    balanced_type = residences.max_by { |_, built| built }.first
    assigned = BigDecimal(0)

    residences.each_key do |type|
      next if type == balanced_type

      share = (residences[type] / total * 100.0).round(RESIDENCE_SHARE_DECIMALS)
      scenario.user_values[SHARE_KEYS[type]] = share
      assigned += BigDecimal(share.to_s)
    end

    scenario.balanced_values[SHARE_KEYS[balanced_type]] = (BigDecimal(100) - assigned).to_f
  end

  # Migrates the demolished residences and returns the residences left standing per type and period,
  # which the insulation conversion needs as a weight.
  def migrate_demolished(scenario)
    EXISTING_PERIODS.each_with_object({}) do |period, residences|
      present = HOUSING_TYPES.to_h do |type|
        [type, present_residences(scenario, period.present_attribute(type))]
      end

      standing = HOUSING_TYPES.to_h do |type|
        [type, scenario.user_values.delete(period.residences_key(type))]
      end

      # The old input set the residences left standing, so the demolished ones are whatever is
      # missing from the residences present today.
      HOUSING_TYPES.each do |type|
        residences[[type, period.name]] =
          standing[type].nil? ? present[type] : [standing[type], present[type]].min
      end

      # If none of the old inputs is present, nothing was demolished in this period.
      next if standing.values.all?(&:nil?)

      # Residences cannot be demolished where there are none. In that case the old inputs could
      # only be zero, so there is nothing to convert, but the keys still go.
      next if present.values.sum.zero?

      demolished = HOUSING_TYPES.sum { |type| present[type] - residences[[type, period.name]] }
      scenario.user_values[period.demolished_key] = demolished.floor.to_f
    end
  end

  # The old inputs set an absolute heating demand in kWh/m2 per housing type, the new input sets the
  # reduction of that demand as a positive percentage for the whole period.
  def migrate_insulation(scenario, residences)
    ALL_PERIODS.each do |period|
      default_demand = 0.0
      requested_demand = 0.0
      touched = false

      # Calculate the heat demand of the whole period twice: as the old inputs asked for it, and as
      # it stands at the default. Every type is visited, since the new input reduces the demand of
      # all four and a type left untouched dilutes the reduction of the ones that were insulated.
      HOUSING_TYPES.each do |type|
        requested = scenario.user_values.delete(period.insulation_level_key(type))
        touched ||= !requested.nil?

        # A region without residences of this type and period has no demand to reduce, so the old
        # value carries no meaning and only its key goes.
        typical_demand = scenario.area[period.demand_attribute(type)].to_f
        next if typical_demand.zero?

        # A type weighs in the shared input by the demand its residences carry.
        weight = insulation_weight(scenario, period, type, residences[[type, period.name]].to_f, typical_demand)
        requested_demand += weight * (requested.nil? ? 1.0 : requested / typical_demand)
        default_demand += weight
      end

      # If none of the old inputs is present, or these residences have no demand left, there is
      # nothing to express.
      next unless touched && default_demand.positive?

      # The new input only expresses a reduction of the demand. A demand above the default is not an
      # insulation improvement and has nowhere to go, so it is left out.
      reduction = ((1.0 - (requested_demand / default_demand)) * 100.0).round(INSULATION_DECIMALS)
      scenario.user_values[period.insulation_key] = reduction if reduction.positive?
    end
  end

  # New residences carry the demand the model builds for them: their number, their floor area and
  # the demand per m2. Residences standing today carry the demand they had in the start year,
  # reduced by the ones demolished since, which is how the model scales them into the future year.
  def insulation_weight(scenario, period, type, residences, typical_demand)
    return residences * FLOOR_AREAS[type] * typical_demand if period == NEW_PERIOD

    present = present_residences(scenario, period.present_attribute(type))
    return 0.0 if present.zero?

    @start_year_demands[scenario.area_code][period.demand_node(type)].to_f * (residences / present)
  end
end
