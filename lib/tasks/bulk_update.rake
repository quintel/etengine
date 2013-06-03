require_relative 'input_defaults'
require 'highline/import'
require 'term/ansicolor'
include Term::ANSIColor

class BulkUpdateHelpers
  class << self
    def save(object, user_values,  dry_run = true)
      if object.is_a?(Preset)
        save_preset(object, user_values, dry_run)
      elsif object.is_a?(Scenario)
        save_scenario(object, user_values, dry_run)
      end
    end

    def show_diff(object, user_values)
      object.user_values.each do |key, value|
        if value != user_values[key]
          puts "Different value in #{key}: #{value} => #{user_values[value]}"
        end
      end
    end

    #######
    private
    #######

    def save_preset(preset, user_values, dry_run)
      return show_diff(preset, user_values) if dry_run
      
      @file_data ||= get_file_data
      
      preset_file_path = @file_data[preset.id][:path]
      preset = YAML::load_file(preset_file_path).with_indifferent_access
      preset[:user_values] = user_values

      File.open(preset_file_path, 'w') do |f|
        f << YAML::dump(preset)
      end
    end

    def save_scenario(scenario, user_values, dry_run)
      return show_diff(scenario, user_values) if dry_run

      puts "> Saving!"
      scenario.update_attributes(:user_values => user_values)
    end

    def preset_dir
      @preset_dir ||= File.join(Etsource::Base.instance.base_dir, 'presets')
    end

    # Returns Hash containing key-value pairs with ID and path of individual
    # presets
    def get_file_data
      file_data = {}
      Dir.glob("#{preset_dir}/**/*.yml").each do |f|
        file = YAML::load_file(f).with_indifferent_access
        file_data[file[:id]] = { path: f }
      end
      file_data
    end
  end
end

namespace :bulk_update do
  desc "This shows the changes that would be applied to gqueries. Pass FORCE=TRUE to update records"
  task :gquery_replace => :environment do
    bootstrap

    @gqueries = Gquery.contains(@from)
    @gqueries.each do |g|
      puts "GQuery #{g.id}".yellow.bold
      puts "Query was: #{highlight(g.query, @from)}"
      g.query = g.query.gsub(@from, @to)
      puts "Query will be: #{highlight(g.query, @to)}"
      puts
      if @force
        puts "Saving record!".green
        g.save
      end
    end
  end

  desc "This shows the changes that would be applied to inputs. Pass FORCE=TRUE to update records"
  task :input_replace => :environment do
    bootstrap
    @inputs = Input.embedded_gql_contains(@from)
    @inputs.each do |i|
      puts "Input #{i.id}".yellow.bold
      [:start_value_gql, :min_value_gql, :max_value_gql, :attr_name].each do |field|
        value = i.send(field)
        next if value.blank?
        next unless value.include?(@from)
        puts "#{field} was: #{highlight(value, @from)}"
        i.send("#{field}=", value.gsub(@from, @to))
        puts "#{field} will be: #{highlight(i.send(field), @to)}"
      end
      puts
      if @force
        puts "Saving record!".green
        i.save
      end
    end
  end

  def bootstrap
    @from  = ENV["FROM"]
    @to    = ENV["TO"]
    @force = ENV["FORCE"] == "TRUE"

    if @force
      unless HighLine.agree("You know what you're doing, right? [y/n]")
        puts "Bye"; exit
      end
    end

    if @from.blank? || @to.blank?
      puts "Missing FROM/TO attribute"; exit
    end
  end

  def highlight(text, token)
    text.gsub(token, token.red)
  end

  desc 'Updates the scenarios. Add PRESETS=1 to only update preset scenarios'
  task :update_scenarios => :environment do
    @dry_run = !ENV['PERFORM']

    if @dry_run
      puts "=== Doing a dry run! (run with PERFORM=1 to execute changes.)"
    else
      @dry_run = !HighLine.agree("Are you sure you want to perform the updates? [y/n]")

      if @dry_run
        puts "=== You have forced to perform, but decided on a dry run."
      else
        puts "=== Doing the changes."
      end
    end

    update_block = proc { |s|
      puts "#{s.class} ##{s.id}: #{s.title}"

      #skip scenario if not nl
      next unless s.area_code == "nl"

      # cleanup unused scenarios
      if s.is_a?(Scenario) && (s.area_code.blank? || (s.title == "API" && s.updated_at  < 14.day.ago ) || s.source == "Mechanical Turk")
        if @dry_run
          puts "> Would be removed, but this is a dry run"
        else
          puts "> REMOVING"
          s.destroy
        end
        next
      end

      begin
        inputs = s.user_values
      rescue
        puts "> Error! cannot load user_values"
        next
      end

      ######## CODE BELOW CHANGES / CHECKS INPUTS OF SCENARIOS #########
      ############################# START ##############################


      # As of deploy on 29-05-2013, many CHPs have different attributes.
      # The statements below correct scenario's for these changes

      # industry_chp_combined_cycle_gas_power_fuelmix has updated capacity
      # and full load hours:
      # elec_out_cap_old: 25.43 MW
      # elec_out_cap_new: 100 MW
      # elec_FLH_old: 5443
      # elec_FLH_new: 8000
      # This results in a delta of el. production per unit of 
      # 100 * 8000 /(25.43 * 5443) ~ 5.78
      # between new and old
      # We need to reduce the number of units with 1.0 / 5.78 ~ 0.173
      # to keep the same el. production
      if inputs["number_of_industry_chp_combined_cycle_gas_power_fuelmix"].nil?
        inputs["number_of_industry_chp_combined_cycle_gas_power_fuelmix"] = INPUT_DEFAULTS["number_of_industry_chp_combined_cycle_gas_power_fuelmix"] 
      else 
        # Scale to keep installed capacity correct.
        inputs["number_of_industry_chp_combined_cycle_gas_power_fuelmix"] *= 0.173
      end

      # industry_chp_turbine_gas_power_fuelmix is new (and should not feature in the odl scenarios)
      inputs["number_of_industry_chp_turbine_gas_power_fuelmix"] = 0.0

      # industry_chp_engine_gas_power_fuelmix is new 
      inputs["number_of_industry_chp_engine_gas_power_fuelmix"] = 0.0

      # industry_chp_supercritical_wood_pellets is removed.
      # WM has chosen the number_of_agriculture_chp_supercritical_wood_pellets to 'replace' it
      # With 1.5 MWe and 7500 FLHs this leads to 
      # industry_chp_supercritical_wood_pellets_production_in_MW / (1.5 * 7500) ~ X units of number_of_agriculture_chp_supercritical_wood_pellets extra.
      number_of_units_old = inputs["industry_number_of_biomass_chp"].nil? ? 0.0 : inputs["industry_number_of_biomass_chp"]
      inputs["number_of_agriculture_chp_supercritical_wood_pellets"] = INPUT_DEFAULTS["number_of_agriculture_chp_supercritical_wood_pellets"] if inputs["number_of_agriculture_chp_supercritical_wood_pellets"].nil?

      old_production = number_of_units_old * 32.5 * 3594.0 # MWH (NoU * Cap)
      extra_number_of_units = old_production / (1.5 * 7500.0) 
      new_number_of_units = inputs["number_of_agriculture_chp_supercritical_wood_pellets"] + extra_number_of_units
      max_number_of_units = 1339
      if new_number_of_units < max_number_of_units
        inputs["number_of_agriculture_chp_supercritical_wood_pellets"] = new_number_of_units
      else
        inputs["number_of_agriculture_chp_supercritical_wood_pellets"] = max_number_of_units
        puts "Setting number_of_agriculture_chp_supercritical_wood_pellets to maximum"
      end

      # number_of_agriculture_chp_engine_biogas is new
      inputs["number_of_agriculture_chp_engine_biogas"] = 0.0

      # number_of_agriculture_chp_supercritical_wood_pellets is new
      inputs["number_of_agriculture_chp_supercritical_wood_pellets"] = 0.0

      # The number_of_agriculture_chp_engine_network_gas chp has a capacity that 
      # is almost 1.97 times smaller than before. To keep the installed capacity the same
      # we must scale the number of units (multiply with 0.51)
      if inputs["number_of_agriculture_chp_engine_network_gas"].nil?
        inputs["number_of_agriculture_chp_engine_network_gas"] = INPUT_DEFAULTS["number_of_agriculture_chp_engine_network_gas"] 
      else 
        # Scale to keep installed capacity correct.
        inputs["number_of_agriculture_chp_engine_network_gas"] *= 0.51
      end

      # The number_of_other_chp_engine_network_gas chp has a capacity that 
      # is almost 4.30 times smaller than before. To keep the installed capacity the same
      # we must increase the number of units (multiply with 0.23)
      if inputs["number_of_other_chp_engine_network_gas"].nil?
        inputs["number_of_other_chp_engine_network_gas"] = INPUT_DEFAULTS["number_of_other_chp_engine_network_gas"] 
      else 
        # Scale to keep installed capacity correct.
        inputs["number_of_other_chp_engine_network_gas"] *= 0.23
      end

      # number_of_other_chp_engine_biogas is new
      inputs["number_of_other_chp_engine_biogas"] = 0.0

      # number_of_co_firing_coal is gone but should be zero everywhere
      number_of_units_old = inputs["number_of_co_firing_coal"].nil? ? 0.0 : inputs["number_of_co_firing_coal"]
      old_production = number_of_units_old * 304 * 6329.0
      old_production_pj = old_production * 3.6 / 1000000
      puts "WARNING: this scenario still has #{old_production_pj} PJ of woodpellets CHP production!" if old_production > 0.0

      # number_of_energy_chp_supercritical_waste_mix is new
      inputs["number_of_energy_chp_supercritical_waste_mix"] = 0.0

      # number_of_energy_chp_ultra_supercritical_coal changed a little bit (become 0.84 times smaller)
      if inputs["number_of_energy_chp_ultra_supercritical_coal"].nil?
        inputs["number_of_energy_chp_ultra_supercritical_coal"] = INPUT_DEFAULTS["number_of_energy_chp_ultra_supercritical_coal"] 
      else 
        # Scale to keep installed capacity correct.
        max_number_of_units = 54.0
        if (inputs["number_of_energy_chp_ultra_supercritical_coal"] * 1.19) < max_number_of_units
          inputs["number_of_energy_chp_ultra_supercritical_coal"] *= 1.19
        else
          inputs["number_of_energy_chp_ultra_supercritical_coal"] = max_number_of_units
          puts "Setting number_of_energy_chp_ultra_supercritical_coal to maximum"
        end
      end

      # The energy_chp_combined_cycle_network_gas chp has a capacity that 
      # is almost 5 times smaller than before. To keep the installed capacity the same
      # we must increase the number of units (multiply with 5)
      if inputs["number_of_energy_chp_combined_cycle_network_gas"].nil?
        inputs["number_of_energy_chp_combined_cycle_network_gas"] = INPUT_DEFAULTS["number_of_energy_chp_combined_cycle_network_gas"] 
      else 
        # Scale to keep installed capacity correct.
        max_number_of_units = 396
        if inputs["number_of_energy_chp_combined_cycle_network_gas"] * 5.06 < max_number_of_units
          inputs["number_of_energy_chp_combined_cycle_network_gas"] *= 5.06
        else
          inputs["number_of_energy_chp_combined_cycle_network_gas"] = max_number_of_units
          puts "Setting number_of_energy_chp_combined_cycle_network_gas to maximum"
        end
      end


      ###################### GENERAL CHECKS ##########################

      # HHs warm water group
      share_group_inputs = [
        "households_water_heater_wood_pellets_share",
        "households_water_heater_coal_share",
        "households_water_heater_resistive_electricity_share",
        "households_water_heater_fuel_cell_chp_network_gas_share",
        "households_water_heater_combined_network_gas_share",
        "households_water_heater_network_gas_share",
        "households_water_heater_district_heating_steam_hot_water_share",
        "households_water_heater_micro_chp_network_gas_share",
        "households_water_heater_crude_oil_share",
        "households_water_heater_heatpump_air_water_electricity_share",
        "households_water_heater_heatpump_ground_water_electricity_share"
      ]

      sum = 0.0
      share_group_inputs.each do |element|
        inputs[element] = INPUT_DEFAULTS[element] if inputs[element].nil?
        sum = sum + inputs[element]
      end

      # Check if the share group adds up to 100% BEFORE scaling
      if !(sum).between?(99.99, 100.01)
        puts "> Warning! Share group of HHs warm water is not 100% in scenario, but is " + (sum).to_s
      end

      # Scaling the group
      scale_factor = sum / 100.0
      sum = 0.0
      share_group_inputs.each do |element|
        inputs[element] /= scale_factor
        sum = sum + inputs[element]
      end

      # Check if the share group adds up to 100% AFTER scaling
      if !(sum).between?(99.99, 100.01)
        puts "> ERROR! Share group of HHs warm water is not 100% in scenario, but is " + (sum).to_s
        exit(1)
      end

      # HHs space heating group
      share_group_inputs = [
      "households_space_heater_heatpump_air_water_electricity_share",
      "households_space_heater_micro_chp_network_gas_share",
      "households_space_heater_electricity_share",
      "households_space_heater_crude_oil_share",
      "households_space_heater_combined_network_gas_share",
      "households_space_heater_heatpump_ground_water_electricity_share",
      "households_space_heater_wood_pellets_share",
      "households_space_heater_coal_share",
      "households_space_heater_network_gas_share",
      "households_space_heater_district_heating_steam_hot_water_share"
      ]

      sum = 0.0
      share_group_inputs.each do |element|
        inputs[element] = INPUT_DEFAULTS[element] if inputs[element].nil?
        sum = sum + inputs[element]
      end

      # Check if the share group adds up to 100% BEFORE scaling
      if !(sum).between?(99.99, 100.01)
        puts "> Warning! Share group of HHs heating is not 100% in scenario, but is " + (sum).to_s

        # default_sum = 0.0
        # puts "Defaults add up to:"
        # share_group_inputs.each do |element|
        #   puts "#{element}: #{INPUT_DEFAULTS[element]}"
        #   default_sum += INPUT_DEFAULTS[element]
        # end
        # puts "Sum: #{default_sum}"
      end

      # Scaling the group
      scale_factor = sum / 100.0
      sum = 0.0
      share_group_inputs.each do |element|
        inputs[element] /= scale_factor
        sum = sum + inputs[element]
      end

      # Check if the share group adds up to 100% AFTER scaling
      if !(sum).between?(99.99, 100.01)
        puts "> ERROR! Share group of HHs space heating is not 100% in scenario, but is " + (sum).to_s
        exit(1)
      end

      # HHs district heating group
      share_group_inputs = [
        "households_collective_chp_network_gas_share",
        "households_collective_chp_wood_pellets_share",
        "households_collective_chp_biogas_share",
        "households_collective_geothermal_share",
        "households_heat_network_connection_steam_hot_water_share"
      ]

      sum = 0.0
      share_group_inputs.each do |element|
        inputs[element] = INPUT_DEFAULTS[element] if inputs[element].nil?
        sum = sum + inputs[element]
      end

      # Check if the share group adds up to 100% BEFORE scaling
      if !(sum).between?(99.99, 100.01)
        puts "> Warning! Share group of Households district heating is not 100% in scenario, but is " + (sum).to_s

        # Setting to defaults!
        puts "Setting Households district heating group to defaults!"
        share_group_inputs.each do |element|
          inputs[element] = INPUT_DEFAULTS[element]
        end
      end

      # Buildings district heating group
      share_group_inputs = [
        "buildings_collective_chp_wood_pellets_share",
        "buildings_collective_chp_network_gas_share",
        "buildings_heat_network_connection_steam_hot_water_share",
        "buildings_collective_geothermal_share"
      ]

      sum = 0.0
      share_group_inputs.each do |element|
        inputs[element] = INPUT_DEFAULTS[element] if inputs[element].nil?
        sum = sum + inputs[element]
      end

      # Check if the share group adds up to 100% BEFORE scaling
      if !(sum).between?(99.99, 100.01)
        puts "> Warning! Share group of Buildings district heating is not 100% in scenario, but is " + (sum).to_s

        # Setting to defaults!
        puts "Setting Buildings district heating group to defaults!"
        share_group_inputs.each do |element|
          inputs[element] = INPUT_DEFAULTS[element]
        end
      end

      #Share group of HHs cooling
      share_group_inputs = [
      "households_cooling_heatpump_ground_water_electricity_share",
      "households_cooling_heatpump_air_water_electricity_share",
      "households_cooling_airconditioning_electricity_share"]

      sum = 0.0
      share_group_inputs.each do |element|
        inputs[element] = INPUT_DEFAULTS[element] if inputs[element].nil?
        sum = sum + inputs[element]
      end

      # Check if the share group adds up to 100% BEFORE scaling
      if !(sum).between?(99.99, 100.01)
          puts "> Warning! Share group of HHs cooling is not 100% in scenario, but is " + (sum).to_s
      end

      # Rounding all inputs
      inputs.each do |x|
        x[1] =x[1].to_f.round(1) unless x[1].nil?
      end

      ######################## END ############################
      BulkUpdateHelpers.save(s, inputs, @dry_run)
    }

    if !ENV['PRESETS'] && !ENV['SCENARIOS']
      puts "Help:"
      puts "-----"
      puts "Append the following options to the rake command:"
      puts "PRESETS=1       Run on the presets"
      puts "SCENARIOS=1     Run on the scenarios"
      puts "PERFORM=1       Run the actions (as in, don't do a dry run)"
    end

    # Update presets
    if !!ENV['PRESETS']
      Preset.all.each do |preset|
        update_block.call preset
      end
    end

    if !!ENV['SCENARIOS']
      Scenario.order('id').find_each(:batch_size => 100) do |scenario|
        update_block.call scenario
      end
    end
  end
end
