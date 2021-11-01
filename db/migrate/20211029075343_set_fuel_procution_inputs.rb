require 'etengine/scenario_migration'

class SetFuelProcutionInputs < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  TIME_OF_FUEL_UPDATE = '01-06-2021'.to_date.freeze

  NEW_INPUTS = {
    nl: {
      2020 => {
        'fuel_production_crude_oil' => 28400,
        'fuel_production_natural_gas' => 552169
      },
      2030 => {
        'fuel_production_crude_oil' => 14200,
        'fuel_production_natural_gas' => 0
      },
      2040 => {
        'fuel_production_crude_oil' => 7100,
        'fuel_production_natural_gas' => 0
      },
      2050 => {
        'fuel_production_crude_oil' => 0,
        'fuel_production_natural_gas' => 0
      }
    },
    de: {
      2020 => {
        'fuel_production_coal' => 166801.3751,
        'fuel_production_lignite' => 1392089.981,
        'fuel_production_natural_gas' => 414279.7162,
        'fuel_production_crude_oil' => 159480.5452,
        'fuel_production_uranium_oxide' => 354771.9584
      },
      2030 => {
        'fuel_production_coal' => 128427.2344,
        'fuel_production_lignite' => 1071827.293,
        'fuel_production_natural_gas' => 259995.7325,
        'fuel_production_crude_oil' => 94514.73514,
        'fuel_production_uranium_oxide' => 0
      },
      2040 => {
        'fuel_production_coal' => 111625.0786,
        'fuel_production_lignite' => 931599.9552,
        'fuel_production_natural_gas' => 115476.9832,
        'fuel_production_crude_oil' => 56171.68825,
        'fuel_production_uranium_oxide' => 0
      },
      2050 => {
        'fuel_production_coal' => 125798.5848,
        'fuel_production_lignite' => 1049889.124,
        'fuel_production_natural_gas' => 98803.98629,
        'fuel_production_crude_oil' => 0,
        'fuel_production_uranium_oxide' => 0
      }
    },
    dk: {
      2020 => {
        'fuel_production_crude_oil' => 343378.3784,
        'fuel_production_natural_gas' => 131488.6874
      },
      2030 => {
        'fuel_production_crude_oil' => 96051.24129,
        'fuel_production_natural_gas' => 54236.30407
      },
      2040 => {
        'fuel_production_crude_oil' => 43016.63202,
        'fuel_production_natural_gas' => 16508.26572
      },
      2050 => {
        'fuel_production_crude_oil' => 12829.52183,
        'fuel_production_natural_gas' => 15209.59372
      }
    }
  }

  # All other countries and years will be set to 0
  ZEROED_INPUTS = {
    'fuel_production_coal' => 0,
    'fuel_production_lignite' => 0,
    'fuel_production_natural_gas' => 0,
    'fuel_production_crude_oil' => 0,
    'fuel_production_uranium_oxide' => 0
  }

  def up
    migrate_scenarios do |scenario|
      # Skip if a single fuel input has been touched
      next unless (scenario.user_values.keys & ZEROED_INPUTS.keys).empty?

      scenario.user_values.merge!(new_inputs_for (scenario))
    end
  end

  def new_inputs_for(scenario)
    NEW_INPUTS.dig(scenario.area_code.to_sym, scenario.end_year) || ZEROED_INPUTS
  end

  def scenarios(since)
    # This update is only for country scenarios, but skip nl2019
    countries = Atlas::Dataset::Full.all.map(&:area)
    countries.delete('nl2019')

    # Only do this for scenarios that were created before the fuel update
    Scenario.migratable.where(area_code: countries).where('created_at <= ?', TIME_OF_FUEL_UPDATE)
  end
end
