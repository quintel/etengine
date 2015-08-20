class RenameOtherIndustryInputs < ActiveRecord::Migration
  RENAMED_INPUTS = {
    industry_useful_demand_crude_oil_non_energetic:
      :industry_useful_demand_for_other_crude_oil_non_energetic,

    industry_useful_demand_useable_heat_efficiency:
      :industry_useful_demand_for_other_useable_heat_efficiency,

    industry_useful_demand_useable_heat:
      :industry_useful_demand_for_other_useable_heat,

    industry_useful_demand_network_gas_non_energetic:
      :industry_useful_demand_for_other_network_gas_non_energetic,

    industry_useful_demand_electricity:
      :industry_useful_demand_for_other_electricity,

    industry_useful_demand_electricity_efficiency:
      :industry_useful_demand_for_other_electricity_efficiency
  }

  RENAMED_INPUTS.to_a.each do |(key, value)|
    RENAMED_INPUTS[key.to_s] = value.to_s
  end

  def up
    rename_inputs(RENAMED_INPUTS)
  end

  def down
    rename_inputs(RENAMED_INPUTS.invert)
  end

  private

  def rename_inputs(keys)
    Scenario.find_each do |scenario|
      any_changed = false

      keys.each do |old, new|
        if scenario.user_values.key?(old)
          scenario.user_values[new] = scenario.user_values.delete(old)
          any_changed = true
        end
      end

      scenario.save(validate: false) if any_changed

      if (scenario.id % 10000).zero?
        puts "Done up to scenario #{ scenario.id }..."
      end
    end

    puts 'All done!'
  end
end
