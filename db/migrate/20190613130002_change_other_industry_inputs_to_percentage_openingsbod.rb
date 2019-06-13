class ChangeOtherIndustryInputsToPercentageOpeningsbod < ActiveRecord::Migration[5.1]
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
    ids = Pathname.new(__FILE__)
      .expand_path
      .dirname
      .join('20190613130000_protect_openingsbod_cp_scenarios/scenario_ids.csv')
      .read
      .lines
      .map(&:to_i)

    Scenario.where(id: ids)
  end
end
