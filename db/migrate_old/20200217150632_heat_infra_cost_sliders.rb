class HeatInfraCostSliders < ActiveRecord::Migration[5.2]
  OLD_INPUTS = [
    'om_costs_heat_network_buildings',
    'investment_costs_heat_network_buildings',
    'om_costs_heat_network_households',
    'investment_costs_heat_network_households'
  ].freeze

  NEW_INPUTS = [
    'costs_heat_infra_outdoors',
    'costs_heat_infra_indoors'
  ].freeze

  HH_INVESTMENT_START_VALUE = 6750.0

  def up
    update_scenarios do |scenario|
      # Unfortunately, values of new sliders cannot be derived from old sliders
      # As a proxy, we look at the household investment costs slider and use it's relative
      # change as an estimate of the new sliders settings
      user_value = scenario.user_values['investment_costs_heat_network_households']

      OLD_INPUTS.each do |input|
        if scenario.user_values.key?(input)
          scenario.user_values.delete(input)
        end
      end

      next unless user_value

      # user_value = scenario.user_values['investment_costs_heat_network_households']
      # calculate update factor
      update_factor = user_value / HH_INVESTMENT_START_VALUE

      NEW_INPUTS.each do |key|
        scenario.user_values[key] = 100.0 * update_factor
      end
    end
  end

  def update_scenarios
    total = scenarios.count
    changed = 0

    say "Checking and migrating #{total} scenarios"

    scenarios.find_each.with_index do |scenario, index|
      if Atlas::Dataset.exists?(scenario.area_code)
        yield(scenario)

        if scenario.changed?
          scenario.save(validate: false, touch: false)
          changed += 1
        end
      end

      if index.positive? && (index % 1000).zero?
        say "#{index + 1}/#{total} (#{changed} migrated)"
      end
    end

    say "#{total}/#{total} (#{changed} migrated)"
  end

  # All protected scenarios, and any unprotected scenarios since Jan 1st 2020
  # will be updated.
  def scenarios
    Scenario.migratable_since(Date.new(2020, 1, 1))
  end
end
