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

  NEW_INPUTS = %i[
    industry_aggregated_other_industry_coal_percentage
    industry_aggregated_other_industry_useable_heat_percentage
    industry_aggregated_other_industry_electricity_percentage
    industry_aggregated_other_industry_crude_oil_percentage
    industry_aggregated_other_industry_network_gas_percentage
    industry_aggregated_other_industry_wood_pellets_percentage
  ].freeze

  def up
    total = scenarios.count
    changed = 0

    say "Checking and migrating #{total} scenarios"

    scenarios.find_each.with_index do |scenario, index|
      updated = OLD_INPUTS.reduce(false) do |memo, (size_input, eff_input)|
        update_input(scenario, size_input, eff_input) || memo
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

    NEW_INPUTS.each do |new_key|
      scenario.user_values[new_key] = new_value
    end

    true
  rescue Atlas::DocumentNotFoundError
    # Dataset no longer exists.
    false
  end

  # All protected scenarios, and any unprotected scenarios since Jan 1st 2018
  # will be updated.
  def scenarios
    Scenario.where(
      '(protected = ? OR created_at >= ?) AND source != ? AND title != ?',
      true, Time.new(2018, 1, 1), 'Mechanical Turk', 'test'
    ).where(<<-SQL)
      (`user_values` IS NOT NULL OR `balanced_values` IS NOT NULL) AND
      (`user_values` != '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess {}\n' OR `balanced_values` != '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess {}\n')
    SQL
  end
end
