class ChangeOtherIndustryInputsToPercentageOm < ActiveRecord::Migration[5.1]
  SCENARIO_IDS = [
    361017, 361024, 361033, 361039, 361042, 362561, 362698, 362701, 362702,
    362705, 362708, 362710, 362712, 362719, 362724, 362774, 362775, 362776,
    362778, 362779, 362784, 362796, 362797, 362800, 362813, 362821, 362822,
    362826, 362827, 362828, 363625, 363626, 363639, 363641, 363643, 363644,
    363646, 363671, 363673, 363674, 363675, 363677, 363679, 364359, 364361,
    364363, 364365, 369748, 370161, 370165, 370167, 370316, 370376, 370539,
    371300, 371303, 371304, 371305, 371307, 371311, 371313, 371329, 371331,
    371333, 371667, 392431, 392442, 392446, 392448, 392458, 392459, 392462,
    392467, 392475, 392494, 392523, 392526, 392585, 392586, 392588, 392614,
    392628, 392637, 392651, 392653, 392664, 392668, 393020, 393034, 393039,
    393041, 393042, 393044, 393046, 393047, 393068, 393073, 393075, 393077,
    393079, 393081, 393097, 393119, 393131, 393133, 393140, 394273, 395436,
    395450, 384608
  ].freeze

  OLD_INPUTS = [
    %i[
      industry_useful_demand_for_other_aggregated_industry_other
      industry_useful_demand_for_other_aggregated_industry_other_efficiency
    ].freeze,
    # "nl" input values prevail over "other"
    %i[
      industry_useful_demand_for_other_aggregated_industry_nl
      industry_useful_demand_for_other_aggregated_industry_nl_efficiency
    ].freeze
  ].freeze

  NEW_INPUT = :industry_useful_demand_for_aggregated_other

  def up
    return unless Rails.env.production?

    total = scenarios.count
    changed = 0

    say "Checking and migrating #{total} scenarios"

    scenarios.find_each.with_index do |scenario, index|
      updated = OLD_INPUTS.reduce(false) do |memo, (size_input, eff_input)|
        update_input(scenario, size_input, eff_input) ||
          clean_inputs(scenario, size_input, eff_input) ||
          memo
      end

      if updated
        scenario.save(validate: false)
        changed += 1
      end

      if index.positive? && (index % 1000).zero?
        say "#{index + 1}/#{total} (#{changed} migrated)"
      end
    end

    say "#{total}/#{total} (#{changed} migrated)"
  end

  def down
    return unless Rails.env.production?
    raise ActiveRecord::IrreversibleMigration
  end

  private

  # Changes an input in a `scenario` from the `from` key to the `to` key,
  # multiplying the value by `multiplier`.
  #
  # If the `from` key is not present, returns a falsey value.
  def update_input(scenario, size_input, efficiency_input)
    return false unless scenario.user_values.key?(size_input)

    size       = scenario.user_values.delete(size_input)
    efficiency = scenario.user_values.delete(efficiency_input) || 0.0
    start_year = Atlas::Dataset.find(scenario.area_code).analysis_year
    end_year   = scenario.end_year

    new_value  = size * (((100.0 - efficiency) / 100)**(end_year - start_year))

    scenario.user_values[NEW_INPUT] = new_value

    true
  rescue Atlas::DocumentNotFoundError
    # Dataset no longer exists.
    false
  end

  # Remove the size and efficiency inputs if still present (the scenario set a
  # value for one, but not the other).
  #
  # Returns true if any values were deleted; false otherwise.
  def clean_inputs(scenario, size_input, efficiency_input)
    deleted = scenario.user_values.delete(size_input)
    scenario.user_values.delete(efficiency_input) || deleted
  end

  def scenarios
    Scenario.where(id: SCENARIO_IDS)
  end
end
