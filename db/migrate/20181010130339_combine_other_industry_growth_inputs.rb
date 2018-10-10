class CombineOtherIndustryGrowthInputs < ActiveRecord::Migration[5.1]
  ORIGINAL_INPUTS = %w[
    industry_aggregated_other_industry_wood_pellets_percentage
    industry_aggregated_other_industry_network_gas_percentage
    industry_aggregated_other_industry_crude_oil_percentage
    industry_aggregated_other_industry_electricity_percentage
    industry_aggregated_other_industry_useable_heat_percentage
    industry_aggregated_other_industry_coal_percentage
  ].freeze

  NEW_KEY = 'industry_useful_demand_for_aggregated_other'.freeze

  def up
    each_scenario_with_progress do |scenario|
      next unless (ORIGINAL_INPUTS & scenario.user_values.keys).any?

      scenario.user_values[NEW_KEY] =
        scenario.user_values.values_at(*ORIGINAL_INPUTS).detect(&:presence)

      ORIGINAL_INPUTS.each do |key|
        scenario.user_values.delete(key)
      end

      scenario.save(validate: false)
      true
    end
  end

  def down
    each_scenario_with_progress do |scenario|
      next unless scenario.user_values.key?(NEW_KEY)

      value = scenario.user_values.delete(NEW_KEY)

      ORIGINAL_INPUTS.each do |key|
        scenario.user_values[key] = value
      end

      scenario.save(validate: false)
      true
    end
  end

  private

  def each_scenario_with_progress
    total = scenarios.count
    changed = 0

    say "Checking and migrating #{total} scenarios"

    scenarios.find_each.with_index do |scenario, index|
      changed += 1 if yield(scenario)

      if index.positive? && (index % 1000).zero?
        say "#{index + 1}/#{total} (#{changed} migrated)"
      end
    end

    say "#{total}/#{total} (#{changed} migrated)"
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
