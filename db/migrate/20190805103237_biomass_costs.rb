# frozen_string_literal: true

class BiomassCosts < ActiveRecord::Migration[5.2]
  # current start value of biomass cost slider
  BIOMASS_START_VALUE = 134.8749893335609

  # new input keys and their start values
  NEW_INPUTS = {
    'costs_wood' => 166.0,
    'costs_biogas' => 57.0,
    'costs_greengas' => 57.52
  }.freeze

  def up
    update_scenarios do |scenario|
      # Skip this scenario unless the biomass costs slider has been set
      next unless scenario.user_values.key?('costs_biomass')

      # Retrieve user value
      biomass_user_value = scenario.user_values['costs_biomass']
      # calculate update factor
      update_factor = biomass_user_value / BIOMASS_START_VALUE

      scenario.user_values.delete('costs_biomass')

      NEW_INPUTS.each do |key, val|
        scenario.user_values[key] = val * update_factor
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

  # All protected scenarios, and any unprotected scenarios since Jan 1st 2019
  # will be updated.
  def scenarios
    Scenario.migratable_since(Date.new(2019, 1, 1))
  end
end
