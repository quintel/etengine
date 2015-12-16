class AddHybridHeatPumpsToScenarios < ActiveRecord::Migration
  HHP   = 'households_space_heater_hybrid_heatpump_air_water_electricity_share'
  ADDON = 'households_space_heater_heatpump_add_on_electricity_share'
  COMBI = 'households_space_heater_combined_network_gas_share'

  COMBI_DEFAULTS = {
    'nl' => 78.97997543697231,
    'br' => 0.0,
    'es' => 0.019544742175342154,
    'de' => 14.07432544617884,
    'pl' => 0.0,
    'uk' => 8.032945539737122,
    'eu' => 6.573955271200788,
    'fr' => 0.9145057749188787
  }

  def up
    total   = Scenario.count
    done    = 0
    updates = 0

    puts "Updating #{ total } scenarios with hybrid heat pumps"

    Scenario.find_each do |scenario|
      if update_inputs(scenario)
        scenario.save(validate: false) 
        updates += 1
      end

      done += 1

      puts "#{ done }/#{ total }" if (done % 5_000).zero?
    end

    puts "Finished #{ done }/#{ total } (#{ updates } updated)"
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end

  private

  def update_inputs(scenario)
    inputs   = scenario.user_values.dup
    balanced = scenario.balanced_values.dup

    if inputs.key?(HHP)
      # The scenario already contains a HHP. It is therefore quite recent, and
      # all we need to do is delete the obsolete add-on input.
      if inputs.key?(ADDON)
        scenario.user_values = inputs.except(ADDON)
        return true
      else
        return false
      end
    end

    if inputs.key?(ADDON)
      # The scenario contains the old add-on input. This input is to be removed
      # and replaced with the hybrid heat-pump. The combi-boiler share is
      # reduced to compensate.
      combi_val =
        inputs[COMBI] ||
        balanced[COMBI] ||
        COMBI_DEFAULTS[scenario.area_code]

      return false unless combi_val

      inputs[HHP]   = [inputs.delete(ADDON), combi_val].min
      inputs[COMBI] = combi_val - inputs[HHP]

      scenario.user_values = inputs
      scenario.balanced_values = balanced.except(COMBI)

      true
    end
  rescue StandardError => ex
    puts "Exception updating scenario #{ scenario.id }"
    raise ex
  end
end
