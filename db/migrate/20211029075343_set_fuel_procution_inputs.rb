class SetFuelProcutionInputs < ActiveRecord::Migration[5.2]

  ELEGIBLE_AREAS = %w[nl nl2019] #etc
  NEW_INPUTS = {
    2030 => {
      input_one: 20,
      input_two: 30,
      input_three: 40
    },
    2035 => {
      input_one: 20,
      input_two: 30,
      input_three: 40
    }
    # ...
  }

  def up
    NEW_INPUTS.each do |end_year, inputs|
      set_scenario_inputs(end_year, inputs)
    end
  end

  def set_scenario_inputs(end_year, inputs)
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
