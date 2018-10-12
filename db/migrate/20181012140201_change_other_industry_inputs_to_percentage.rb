class ChangeOtherIndustryInputsToPercentage < ActiveRecord::Migration[5.1]
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

  # All protected scenarios, and any unprotected scenarios since Jan 1st 2018
  # will be updated.
  def scenarios
    Scenario.migratable_since(Date.new(2018, 1, 1))
  end
end
