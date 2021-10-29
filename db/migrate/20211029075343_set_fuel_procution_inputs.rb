class SetFuelProcutionInputs < ActiveRecord::Migration[5.2]

  ELEGIBLE_AREAS = %w[nl nl2019 dk de] #etc
  NEW_INPUTS = {
    nl => {
      2020 => {
        fuel_production_crude_oil: 28400,
        fuel_production_natural_gas: 552169
      },
      2030 => {
        fuel_production_crude_oil: 14200,
        fuel_production_natural_gas: 0
      },
      2040 => {
        fuel_production_crude_oil: 7100,
        fuel_production_natural_gas: 0
      },
      2050 => {
        fuel_production_crude_oil: 0,
        fuel_production_natural_gas: 0
      },
    }
    nl2019 => {
      2020 => {
        fuel_production_crude_oil: 28400,
        fuel_production_natural_gas: 552169
      },
      2030 => {
        fuel_production_crude_oil: 14200,
        fuel_production_natural_gas: 0
      },
      2040 => {
        fuel_production_crude_oil: 7100,
        fuel_production_natural_gas: 0
      },
      2050 => {
        fuel_production_crude_oil: 0,
        fuel_production_natural_gas: 0
      },
    }
    de => {
      2020 => {
        fuel_production_coal: 166801.3751,
        fuel_production_lignite: 1392089.981,
        fuel_production_natural_gas: 414279.7162,
        fuel_production_crude_oil: 159480.5452,
        fuel_production_uranium_oxide: 354771.9584
      },
      2030 => {
        fuel_production_coal: 128427.2344,
        fuel_production_lignite: 1071827.293,
        fuel_production_natural_gas: 259995.7325,
        fuel_production_crude_oil: 94514.73514,
        fuel_production_uranium_oxide: 0
      },
      2040 => {
        fuel_production_coal: 111625.0786,
        fuel_production_lignite: 931599.9552,
        fuel_production_natural_gas: 115476.9832,
        fuel_production_crude_oil: 56171.68825,
        fuel_production_uranium_oxide: 0
      },
      2050 => {
        fuel_production_coal: 125798.5848,
        fuel_production_lignite: 1049889.124,
        fuel_production_natural_gas: 98803.98629,
        fuel_production_crude_oil: 0,
        fuel_production_uranium_oxide: 0
      },
    },
    dk => {
      2020 => {
        fuel_production_crude_oil: 343378.3784,
        fuel_production_natural_gas: 131488.6874
      },
      2030 => {
        fuel_production_crude_oil: 96051.24129,
        fuel_production_natural_gas: 54236.30407
      },
      2040 => {
        fuel_production_crude_oil: 43016.63202,
        fuel_production_natural_gas: 16508.26572
      },
      2050 => {
        fuel_production_crude_oil: 12829.52183,
        fuel_production_natural_gas: 15209.59372
      },
    }
    # ...
  }

  def up
    NEW_INPUTS.each do |area_code, end_year, inputs|
      set_scenario_inputs(end_year, inputs)
    end
  end

  def set_scenario_inputs(area_code, end_year, inputs)
    total = scenarios(end_year).count
    say "End Year #{end_year}: #{total} candidate scenarios for migration"

    scenarios(end_year).find_each.with_index do |scenario, index|
      scenario.user_values.merge!(inputs)
      scenario.save(validate: false, touch: false)

      if index.positive? && ((index + 1) % 1000).zero?
        say "#{index + 1}/#{total} migrated", subitem: true
      end
    end

    say "#{total}/#{total} migrated", subitem: true
  end

  def scenarios(end_year)
    Scenario.migratable.where(area_code: ELEGIBLE_AREAS, end_year: end_year)
  end

  def down
    ActiveRecord::IrreversibleMigration
  end
end
