require 'etengine/scenario_migration'

class SetFuelProcutionInputs < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  TIME_OF_FUEL_UPDATE = '01-06-2021'.to_date.freeze

  NEW_INPUTS = {
    nl: {
      2020 => {
        'fuel_production_crude_oil' => 28.4,
        'fuel_production_natural_gas' => 552.169
      },
      2030 => {
        'fuel_production_crude_oil' => 14.2,
        'fuel_production_natural_gas' => 0
      },
      2040 => {
        'fuel_production_crude_oil' => 7.1,
        'fuel_production_natural_gas' => 0
      },
      2050 => {
        'fuel_production_crude_oil' => 0,
        'fuel_production_natural_gas' => 0
      }
    },
    de: {
      2020 => {
        'fuel_production_coal' => 166.8013751,
        'fuel_production_lignite' => 1392.089981,
        'fuel_production_natural_gas' => 414.2797162,
        'fuel_production_crude_oil' => 159.4805452,
        'fuel_production_uranium_oxide' => 354.7719584
      },
      2030 => {
        'fuel_production_coal' => 128.4272344,
        'fuel_production_lignite' => 1071.827293,
        'fuel_production_natural_gas' => 259.9957325,
        'fuel_production_crude_oil' => 94.51473514,
        'fuel_production_uranium_oxide' => 0
      },
      2040 => {
        'fuel_production_coal' => 111.6250786,
        'fuel_production_lignite' => 931.5999552,
        'fuel_production_natural_gas' => 115.4769832,
        'fuel_production_crude_oil' => 56.17168825,
        'fuel_production_uranium_oxide' => 0
      },
      2050 => {
        'fuel_production_coal' => 125.7985848,
        'fuel_production_lignite' => 1049.889124,
        'fuel_production_natural_gas' => 98.80398629,
        'fuel_production_crude_oil' => 0,
        'fuel_production_uranium_oxide' => 0
      }
    },
    dk: {
      2020 => {
        'fuel_production_crude_oil' => 343.3783784,
        'fuel_production_natural_gas' => 131.4886874
      },
      2030 => {
        'fuel_production_crude_oil' => 96.05124129,
        'fuel_production_natural_gas' => 54.23630407
      },
      2040 => {
        'fuel_production_crude_oil' => 43.01663202,
        'fuel_production_natural_gas' => 16.50826572
      },
      2050 => {
        'fuel_production_crude_oil' => 12.82952183,
        'fuel_production_natural_gas' => 15.20959372
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
