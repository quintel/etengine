require 'highline/import'
require 'term/ansicolor'
include Term::ANSIColor

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

  desc 'Convenience method. runs the 3 rake task after each other'
  task :update_presets => :environment do
    ENV['PRESETS'] = "1"
    Rake::Task["bulk_update:update_db_presets"].invoke
    Rake::Task["bulk_update:update_scenarios"].invoke
    Rake::Task["bulk_update:update_etsource_presets"].invoke
  end

  desc 'Takes the etsource/presets and stores them in the database'
  task :update_db_presets => :environment do
    bkp_path = "#{Rails.root}/tmp/scenarios_backup_#{Time.now.to_i}"
    FileUtils.mkdir_p(bkp_path)

    presets = Preset.all
    presets.each do |preset|
      puts "Updating preset #{preset.id}"

      scenario = Scenario.find_by_id(preset.id)

      # backing up in case we overwrite something wrong
      puts "writing backup files to: #{bkp_path}"
      File.open("#{bkp_path}/scenarios_#{scenario.id}.yml", 'w') do |f|
        f << YAML::dump(scenario.attributes)
      end

      # if no scenario with that id, create one with same preset id
      unless scenario
        puts "** Create new scenario db record for #{preset.id}"
        scenario = preset.to_scenario
        scenario.preset_scenario_id = nil
        scenario.save!
        Scenario.update_all("id = #{preset.id}", "id = #{scenario.id}")
        scenario.reload
      end

      # overwrite scenario user_values with presets from etsource.
      scenario.user_values = preset.user_values
      puts scenario.changed? ? "** Saving new values" : "** Nothing changed"
      scenario.save!
    end
  end

  desc 'Updates etsource/presets/ yml files with database records'
  task :update_etsource_presets => :environment do
    Preset.all.each do |preset|
      puts "Updating etsource/preset #{preset.id}"
      scenario     = Scenario.find(preset.id)
      etsource_dir = Etsource::Base.instance.base_dir
      preset_file  = "#{etsource_dir}/presets/scenarios_#{preset.id}.yml"
      yml = YAML::load(File.read(preset_file))
      yml['user_values'] = scenario.user_values.to_hash

      puts "** saving to: #{preset_file}"
      File.open(preset_file, 'w') { |f| f << YAML::dump(yml) }
    end
    puts "\n\n"
    puts "#"*40
    puts "You can revert the changes by running path/to/etsource $ git checkout presets"
  end

  desc 'Updates the scenarios. Add PRESETS=1 to only update preset scenarios'
  task :update_scenarios => :environment do
    unless ENV['PRESETS']
      if HighLine.agree("You want to update only preset? [y/n]")
         ENV['PRESETS'] = "1"
      end
    end
    if ENV['PRESETS'] 
      scenario_scope = Scenario.where(:id => Preset.all.map(&:id))
      puts "Trying to updating #{scenario_scope.length} presets"
    else
      puts "!!!!Look out this script isn't designed for all scenario's. only for preset scenarios!!!!"
      scenario_scope = Scenario.order('id')
    end
    @update_records = HighLine.agree("You want to update records, right? [y/n]")
    
    #store all inputs lookup id with key
    input_info = Input.all
    inputs_key = {}
    input_info.each do |x|
      inputs_key[x.lookup_id] = x.key
    end
    
    ##########################################################
    # Following lines describe the changes of scenarios in the
    # deploy of August 28 2012
    defaults = {"households_replacement_of_existing_houses"=>0.0,
      "households_efficiency_fridge_freezer"=>0.0,
      "costs_oil"=>0.0,
      "investment_costs_wind_onshore"=>0.0,
      "investment_costs_wind_offshore"=>0.0,
      "investment_costs_combustion_gas_plant"=>0.0,
      "investment_costs_combustion_oil_plant"=>0.0,
      "investment_costs_combustion_coal_plant"=>0.0,
      "investment_costs_combustion_biomass_plant"=>0.0,
      "households_lighting_low_energy_light_bulb_share"=>20.0,
      "households_lighting_light_emitting_diode_share"=>0.0,
      "households_market_penetration_solar_panels"=>0.0,
      "households_heating_solar_thermal_panels_share"=>0.0,
      "households_heating_micro_chp_share"=>0.0,
      "households_heating_electric_heater_share"=>1.759974,
      "costs_coal"=>0.0,
      "costs_gas"=>0.0,
      "costs_biomass"=>0.0,
      "investment_costs_water_river"=>0.0,
      "investment_costs_water_mountains"=>0.0,
      "om_costs_nuclear_nuclear_plant"=>0.0,
      "om_costs_wind_onshore"=>0.0,
      "om_costs_wind_offshore"=>0.0,
      "om_costs_water_river"=>0.0,
      "om_costs_water_mountains"=>0.0,
      "om_costs_earth_geothermal_electricity"=>0.0,
      "investment_costs_solar_solar_panels"=>0.0,
      "investment_costs_solar_concentrated_solar_power"=>0.0,
      "investment_costs_nuclear_nuclear_plant"=>0.0,
      "costs_co2"=>0.0,
      "costs_co2_free_allocation"=>85.0,
      "om_costs_co2_ccs"=>0.0,
      "investment_costs_co2_ccs"=>0.0,
      "transport_cars"=>0.0,
      "transport_trucks"=>0.0,
      "transport_trains"=>0.0,
      "transport_domestic_flights"=>0.0,
      "transport_inland_navigation"=>0.0,
      "transport_cars_electric_share"=>0.0,
      "transport_cars_diesel_share"=>47.152636,
      "transport_cars_gasoline_share"=>48.126123,
      "transport_trucks_gasoline_share"=>0.0,
      "transport_trucks_diesel_share"=>100.0,
      "transport_trucks_electric_share"=>0.0,
      "industry_efficiency_electricity"=>0.0,
      "industry_heat_from_fuels"=>0.0,
      "transport_efficiency_electric_vehicles"=>0.0,
      "policy_area_onshore_land"=>83.916083,
      "policy_area_onshore_coast"=>16.666666,
      "om_costs_combustion_gas_plant"=>0.0,
      "om_costs_combustion_oil_plant"=>0.0,
      "om_costs_combustion_coal_plant"=>0.0,
      "om_costs_combustion_biomass_plant"=>0.0,
      "costs_uranium"=>0.0,
      "transport_efficiency_combustion_engine_cars"=>0.0,
      "transport_efficiency_ships"=>0.0,
      "transport_efficiency_airplanes"=>0.0,
      "policy_area_roofs_for_solar_panels"=>0.0,
      "policy_area_land_for_solar_panels"=>0.0,
      "policy_area_land_for_csp"=>0.0,
      "policy_area_biomass"=>5393.1818,
      "policy_area_green_gas"=>0.0,
      "policy_sustainability_co2_emissions"=>0.0,
      "industry_non_energetic_other_demand"=>0.0,
      "households_electricity_demand_per_person"=>0.0,
      "households_cooling_demand_per_person"=>0.0,
      "industry_non_energetic_oil_demand"=>0.0,
      "policy_dependence_max_dependence"=>50.0,
      "policy_cost_electricity_cost"=>0.0,
      "policy_cost_total_energy_cost"=>0.0,
      "policy_grid_baseload_maximum"=>60.0,
      "policy_grid_intermittent_maximum"=>30.0,
      "policy_dependence_max_electricity_dependence"=>50.0,
      "industry_electricity_demand"=>0.0,
      "industry_heat_demand"=>0.0,
      "industry_heating_gas_fired_heater_share"=>37.647787,
      "industry_heating_oil_fired_heater_share"=>29.750778,
      "industry_heating_coal_fired_heater_share"=>3.3930112,
      "industry_heating_biomass_fired_heater_share"=>0.4954397,
      "agriculture_electricity_demand"=>0.0,
      "agriculture_heat_demand"=>0.0,
      "agriculture_heating_oil_fired_heater_share"=>13.173528,
      "agriculture_heating_biomass_fired_heater_share"=>0.635429,
      "agriculture_heating_heat_pump_with_ts_share"=>0.3862728,
      "agriculture_heating_geothermal_share"=>0.104398,
      "other_electricity_demand"=>0.0,
      "other_heat_demand"=>0.0,
      "investment_costs_combustion_waste_incinerator"=>0.0,
      "om_costs_combustion_waste_incinerator"=>0.0,
      "policy_area_offshore"=>13.737373,
      "policy_sustainability_renewable_percentage"=>3.2088979,
      "transport_cars_lpg_share"=>4.5715361,
      "transport_cars_compressed_gas_share"=>0.1497037,
      "transport_trucks_compressed_gas_share"=>0.0,
      "transport_efficiency_trains"=>0.0,
      "households_heating_small_gas_chp_share"=>0.0,
      "households_lighting_incandescent_share"=>80.0,
      "agriculture_heating_gas_fired_heater_share"=>28.281435,
      "investment_costs_earth_geothermal_electricity"=>0.0,
      "households_heating_oil_fired_heater_share"=>1.2426933,
      "number_of_pulverized_coal"=>3.3914141,
      "number_of_pulverized_coal_ccs"=>0.0,
      "number_of_coal_iggc"=>0.322704,
      "number_of_coal_igcc_ccs"=>0.0,
      "number_of_coal_oxyfuel_ccs"=>0.0,
      "number_of_gas_conventional"=>4.8282828,
      "number_of_gas_ccgt"=>5.1045918,
      "number_of_oil_fired_plant"=>0.0,
      "number_of_nuclear_3rd_gen"=>0.31875,
      "electricity_bio_oil_share_in_gas_production"=>0.0,
      "number_of_co_firing_coal"=>0.5984861,
      "number_of_wind_onshore_land"=>419.58041,
      "number_of_wind_onshore_coast"=>83.333333,
      "number_of_wind_offshore"=>68.686868,
      "number_of_hydro_river"=>3.6999999,
      "number_of_hydro_mountain"=>0.0,
      "number_of_geothermal_electric"=>0.0,
      "number_of_waste_incinerator"=>11.690721,
      "number_of_biomass_chp_fixed"=>7.41075,
      "number_of_micro_chp_fixed"=>0.0,
      "number_of_small_chp_fixed"=>4017.4505,
      "number_of_large_gas_chp"=>4.2642393,
      "number_of_decentral_coal_chp_fixed"=>0.0,
      "number_of_small_gas_chp_fixed"=>4017.4505,
      "number_of_gas_fired_heater_fixed"=>7887456.3,
      "number_of_oil_fired_heater_fixed"=>110967.24,
      "number_of_coal_fired_heaterv"=>4983.511,
      "number_of_electric_heat_pump_fixed"=>31330.64,
      "number_of_solar_water_heater_fixed"=>72737.443,
      "number_of_geothermal_fixed"=>0.8898758,
      "transport_diesel_share"=>98.544176,
      "transport_biodiesel_share"=>1.4558239,
      "transport_gasoline_share"=>96.958812,
      "transport_bio_ethanol_share"=>3.0411879,
      "number_of_solar_pv_plants"=>0.0,
      "number_of_concentrated_solar_power"=>0.0,
      "number_of_solar_pv_roofs_fixed"=>0.0,
      "number_of_coal_conventional"=>0.0,
      "number_of_coal_lignite"=>0.0,
      "households_heating_gas_fired_heat_pump_share"=>0.0030104,
      "other_number_of_small_gas_chp"=>0.0,
      "industry_number_of_gas_chp"=>122.08775,
      "industry_number_of_biomass_chp"=>7.41075,
      "agriculture_number_of_small_gas_chp"=>3023.581,
      "industry_heating_combined_heat_power_share"=>28.712982,
      "agriculture_heating_combined_heat_power_share"=>57.418935,
      "transport_efficiency_combustion_engine_trucks"=>0.0,
      "households_heating_gas_combi_heater_share"=>82.100886,
      "households_number_of_inhabitants"=>0.0,
      "households_insulation_level_old_houses"=>1.0,
      "households_insulation_level_new_houses"=>2.5,
      "households_heating_heat_pump_ground_share"=>0.0748925,
      "households_heating_heat_pump_add_on_share"=>0.0374462,
      "households_heating_pellet_stove_share"=>2.55678,
      "households_heating_heat_network_share"=>100.0,
      "households_heating_biomass_chp_share"=>0.0,
      "households_heating_geothermal_share"=>0.0,
      "households_hot_water_gas_water_heater_share"=>13.578585,
      "households_hot_water_electric_boiler_share"=>7.0920372,
      "households_hot_water_solar_water_heater_share"=>0.9046521,
      "households_cooling_heat_pump_ground_share"=>0.0748925,
      "households_cooling_gas_fired_heat_pump_share"=>0.0030104,
      "households_cooling_airconditioning_share"=>100.0,
      "households_cooking_gas_share"=>59.918324,
      "households_cooking_electric_share"=>16.03267,
      "households_cooking_halogen_share"=>8.016335,
      "households_cooking_induction_share"=>16.03267,
      "households_efficiency_dish_washer"=>0.0,
      "households_efficiency_vacuum_cleaner"=>0.0,
      "households_efficiency_washing_machine"=>0.0,
      "households_efficiency_dryer"=>0.0,
      "households_efficiency_television"=>0.0,
      "households_efficiency_computer_media"=>0.0,
      "households_behavior_standby_killer_turn_off_appliances"=>0.0,
      "households_behavior_turn_off_the_light"=>0.0,
      "households_behavior_close_windows_turn_off_heating"=>0.0,
      "households_efficiency_low_temperature_washing"=>0.0,
      "households_heat_demand_per_person"=>0.0,
      "households_hot_water_demand_per_person"=>0.0,
      "households_cooling_heatpump_air_water_electricity_share"=>0.0,
      "households_space_heater_heatpump_air_water_electricity_share"=>0.0,
      "buildings_number_of_buildings"=>0.0,
      "buildings_electricity_per_student_employee"=>0.0,
      "buildings_heat_per_employee_student"=>0.0,
      "buildings_insulation_level"=>1.0,
      "buildings_heating_gas_fired_heater_share"=>84.175631,
      "buildings_heating_biomass_chp_share"=>0.0,
      "buildings_heating_small_gas_chp_share"=>5.0903814,
      "buildings_heating_electric_heater_share"=>1.01626,
      "buildings_heating_heat_network_share"=>1.0109924,
      "buildings_heating_solar_thermal_panels_share"=>0.0188546,
      "buildings_heating_gas_fired_heat_pump_share"=>3.22,
      "buildings_cooling_gas_fired_heat_pump_share"=>0.0,
      "buildings_cooling_heat_pump_with_ts_share"=>0.0,
      "buildings_cooling_airconditioning_share"=>100.0,
      "buildings_heating_heat_pump_with_ts_share"=>2.0077333,
      "buildings_ventilation_rate"=>2.5,
      "buildings_recirculation"=>10.0,
      "buildings_waste_heat_recovery"=>20.0,
      "buildings_appliances_efficiency"=>0.0,
      "buildings_lighting_fluorescent_tube_conventional_share"=>75.0,
      "buildings_lighting_fluorescent_tube_high_performance_share"=>24.0,
      "buildings_lighting_led_tube_share"=>1.0,
      "buildings_lighting_motion_detection"=>26.489399,
      "buildings_lighting_daylight_dependent_control"=>20.46843,
      "buildings_market_penetration_solar_panels"=>0.2415862,
      "buildings_heating_biomass_fired_heater_share"=>0.0,
      "buildings_cooling_per_student_employee"=>0.0,
      "buildings_heating_oil_fired_heater_share"=>3.4601463,
      "households_heating_coal_fired_heater_share"=>0.0615575,
      "households_efficiency_other"=>0.0,
      "number_of_nuclear_conventional"=>0.0,
      "number_of_biomass_fired_heater_fixed"=>206883.27,
      "number_of_gas_fired_heat_pump_fixed"=>4.9450755,
      "number_of_gas_ccgt_ccs"=>0.0,
      "households_water_heater_heatpump_ground_water_electricity_share"=>0.0,
      "households_hot_water_heat_network_share"=>2.3840614,
      "number_of_lignite_chp"=>0.0,
      "transport_planes_fossil_fuel_share"=>100.0,
      "transport_planes_bio_ethanol_share"=>0.0,
      "transport_ships_diesel_share"=>100.0,
      "transport_ships_bio_diesel_share"=>0.0,
      "transport_trains_coal_share"=>0.0,
      "transport_trains_diesel_share"=>7.0,
      "transport_trains_electric_share"=>93.0,
      "number_of_coal_fired_heater_district"=>0.0,
      "number_of_biomass_fired_heater_district"=>0.0,
      "number_of_gas_fired_heater_district"=>0.0,
      "number_of_waste_fired_heater_district"=>0.0,
      "households_hot_water_oil_fired_heater_share"=>0.0,
      "households_cooking_biomass_share"=>0.0,
      "number_of_lignite_chp_fixed"=>0.0,
      "households_hot_water_fuel_cell_share"=>0.0,
      "households_heating_gas_fired_heater_share"=>9.1223511,
      "households_hot_water_coal_fired_heater_hotwater_share"=>0.0,
      "households_hot_water_biomass_heater_share"=>0.0,
      "households_hot_water_micro_chp_share"=>0.0,
      "households_hot_water_gas_fired_heater_share"=>76.945316,
      "policy_cost_energy_use"=>0.0,
      "industry_demand"=>0.0,
      "green_gas_total_share"=>0.0602653,
      "natural_gas_total_share"=>99.939734,
      "mw_of_nuclear_3rd_gen"=>525.93749,
      "mw_of_pulverized_coal"=>2713.1313,
      "mw_of_gas_conventional"=>3862.6262,
      "mw_of_onshore_land"=>1258.7412,
      "mw_of_onshore_coast"=>250.0,
      "mw_of_offshore"=>206.0606,
      "mw_of_hydro_river"=>37.0,
      "mw_of_geothermal_electric"=>0.0,
      "mw_of_waste_incinerator"=>649.48453,
      "mw_of_solar_pv_roofs"=>83.75,
      "mw_of_solar_pv_plants"=>0.0,
      "mw_of_concentrated_solar_power"=>0.0,
      "mw_of_pulverized_coal_ccs"=>0.0,
      "mw_of_coal_iggc"=>258.16326,
      "mw_of_coal_igcc_ccs"=>0.0,
      "mw_of_coal_conventional"=>0.0,
      "mw_of_coal_oxyfuel_ccs"=>0.0,
      "mw_of_coal_lignite"=>0.0,
      "mw_of_electricity_central_coal_chp"=>1687.2727,
      "mw_of_gas_ccgt"=>4083.6734,
      "mw_of_gas_ccgt_ccs"=>0.0,
      "mw_of_electricity_small_chp"=>6575.8853,
      "mw_of_electricity_micro_chp"=>0.0,
      "mw_of_oil_fired_plant"=>0.0,
      "mw_of_nuclear_conventional"=>0.0,
      "mw_of_electricity_large_gas_chp"=>3373.0612,
      "mw_of_co_firing_coal"=>478.78893,
      "mw_of_electricity_biomass_chp"=>241.0,
      "mw_of_heat_central_coal_chp_fixed"=>411.52993,
      "mw_of_heat_micro_chp_fixed"=>0.0,
      "mw_of_heat_large_gas_chp_fixed"=>1993.1725,
      "mw_of_heat_small_gas_chp_fixed"=>10121.583,
      "mw_of_heat_lignite_chp_fixed"=>0.0,
      "mw_of_heat_gas_fired_heater"=>165715.22,
      "mw_of_heat_oil_fired_heater"=>24783.622,
      "mw_of_heat_coal_fired_heater"=>3144.9206,
      "mw_of_heat_gas_fired_heat_pump"=>301.66734,
      "mw_of_heat_coal_fired_heater_district"=>0.0,
      "mw_of_heat_gas_fired_heater_district"=>0.0,
      "mw_of_heat_waste_fired_heater_district"=>0.0,
      "mw_of_heat_biomass_chp_fixed"=>421.75,
      "mw_of_heat_biomass_fired_heater_fixed"=>2601.5483,
      "mw_of_heat_biomass_fired_heater_district"=>0.0,
      "mw_of_heat_geothermal_fixed"=>7.5639448,
      "mw_of_heat_solar_water_heater_fixed"=>315.01754,
      "mw_of_heat_other_small_gas_chp"=>0.0,
      "mw_of_heat_industry_gas_chp"=>5865.0,
      "mw_of_heat_industry_biomass_chp"=>421.75,
      "mw_of_heat_agriculture_small_gas_chp"=>3727.7027,
      "number_of_backup_burner_fixed"=>12.784931,
      "buildings_cooling_cooling_network_share"=>0.0,
      "number_of_central_coal_chp"=>2.0597394,
      "mw_of_hydro_mountain"=>0.0,
      "mw_of_electricity_decentral_coal_chp_fixed"=>0.0,
      "mw_of_heat_decentral_coal_chp_fixed"=>0.0,
      "mw_of_heat_backup_burner_fixed"=>1278.4931,
      "mw_of_electricity_lignite_chp"=>0.0,
      "share_biomass_co_firing_coal"=>0.0,
      "share_biocoal_co_firing_coal"=>0.0,
      "share_coal_co_firing_coal"=>100.0,
      "electricity_natural_gas_share"=>92.417914,
      "pj_of_heat_import"=>0.0,
      "coal_from_south_africa_share"=>26.3,
      "coal_from_north_america_share"=>16.9,
      "coal_from_australia_share"=>15.3,
      "coal_from_eastern_europe_share"=>8.8,
      "coal_from_russia_share"=>0.0,
      "coal_from_south_america_share"=>20.3,
      "coal_from_east_asia_share"=>12.4,
      "coal_from_western_europe_share"=>0.0,
      "gas_from_nederlands_share"=>90.0,
      "gas_from_russia_share"=>5.0,
      "oil_from_north_america_share"=>0.0,
      "oil_from_south_america_share"=>0.0,
      "gas_from_norway_share"=>5.0,
      "gas_from_algeria_share"=>0.0,
      "gas_from_middle_east_share"=>0.0,
      "uranium_from_kazachstan_share"=>100.0,
      "uranium_from_australia_share"=>0.0,
      "uranium_from_canada_share"=>0.0,
      "electricity_oil_share_in_gas_production"=>7.5820854,
      "households_heating_district_heating_network_share"=>3.0404083,
      "number_of_gas_turbines"=>1.4421768,
      "number_of_diesel_generators"=>0.0,
      "initial_updates_preset_demands"=>2040.0,
      "standalone_electric_cars_share"=>0.0,
      "buildings_heating_geothermal_share"=>0.0}
      
      
    scenario_scope.find_each(:batch_size => 100) do |s|
      puts "Scenario ##{s.id}"
      
      #skip scenario if not nl
      next unless s.area_code == "nl"
      
      # cleanup unused scenarios
      if s.area_code.blank? || (s.title == "API" && s.updated_at  < 14.day.ago ) || s.source == "Mechanical Turk"
        puts "INFO: scenario removed"
        s.destroy
        next
      end

      begin
        inputs = s.user_values
      rescue
        puts "Error! cannot load user_values"
        next
      end
      
      #update user values to key last time to do this. API v3 is this default
      new_inputs = {}
      inputs.each do |x|
        # convert strings values to float
        if x[1].is_a?(String)
          begin
            x[1] = Float(x[1])
            puts "Round to float"
          rescue
            puts "Error! cannot convert string to float round #{x[0]}"
            next
          end          
        end
        
        key = x[0]
        if key.is_a?(Integer) &&  inputs_key.has_key?(key)
          key = inputs_key[key]
          new_inputs[key] = x[1]
        end
      end
      inputs = new_inputs

      # Rounding all inputs
      inputs.each do |x|
        x[1] =x[1].round(1) unless x[1].nil?
      end

      ################ END ####################################

      if @update_records || ENV['PRESETS']
        puts "saving"
        s.update_attributes!(:user_values => inputs)
      end

    end    
  end
end
