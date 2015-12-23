class RenameTwoInputs < ActiveRecord::Migration
  INPUTS = {
    'agriculture_chp_supercritical_wood_pellets' =>
      'investment_costs_combustion_biomass_plants',
    'buildings_useful_demand_cooling_electricity' =>
      'buildings_useful_demand_electricity'
  }

  def up
    total   = Scenario.count
    done    = 0
    updated = 0

    Scenario.find_each do |scenario|
      done += 1

      if INPUTS.map { |from, to| change_input(scenario, from, to) }.any?
        scenario.save(validate: false)
        updated += 1
      end

      if (done % 2500).zero?
        puts "Done #{ done } of #{ total } (#{ updated } updated)"
      end
    end
  end

  def down
    Scenario.find_each do |scenario|
      if INPUTS.map { |to, from| change_input(scenario, from, to) }.any?
        scenario.save(validate: false)
      end
    end
  end

  private

  def change_input(scenario, from, to)
    if scenario.user_values && scenario.user_values.key?(from)
      values     = scenario.user_values.dup
      values[to] = values.delete(from)

      scenario.user_values = values

      true
    elsif scenario.balanced_values && scenario.balanced_values.key?(from)
      values     = scenario.balanced_values.dup
      values[to] = values.delete(from)

      scenario.balanced_values = values

      true
    else
      false
    end
  end
end
