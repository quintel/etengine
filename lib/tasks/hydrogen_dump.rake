INPUTS = %w[
  households_heater_combined_hydrogen_share
  households_heater_hybrid_hydrogen_heatpump_air_water_electricity_share
  buildings_space_heater_combined_hydrogen_share
  buildings_space_heater_hybrid_hydrogen_heatpump_air_water_electricity_share
  transport_car_using_hydrogen_share
  transport_bus_using_hydrogen_share
  transport_plane_using_hydrogen_share
  transport_ship_using_hydrogen_share
  transport_freight_train_using_hydrogen_share
  bunkers_ship_using_hydrogen_share
  transport_passenger_train_using_hydrogen_share
  transport_truck_using_hydrogen_share
  transport_van_using_hydrogen_share
  agriculture_burner_hydrogen_share
  industry_aggregated_other_industry_hydrogen_share_energetic
  industry_aggregated_other_industry_hydrogen_share_non_energetic
  industry_chemicals_fertilizers_local_ammonia_local_hydrogen_share
  industry_chemicals_fertilizers_local_ammonia_central_hydrogen_share
  industry_chemicals_fertilizers_burner_hydrogen_share
  industry_chemicals_other_burner_hydrogen_share
  industry_chemicals_other_hydrogen_non_energetic_share
  industry_chemicals_refineries_burner_hydrogen_share
  industry_other_food_burner_hydrogen_share
  industry_other_paper_burner_hydrogen_share
  industry_steel_dri_hydrogen_share
  industry_aluminium_electrolysis_bat_electricity_share
  industry_aluminium_electrolysis_current_electricity_share
  volume_of_baseload_export_hydrogen
  capacity_of_energy_power_turbine_hydrogen
  capacity_of_energy_power_combined_cycle_hydrogen
  capacity_of_energy_hydrogen_wind_turbine_offshore
  capacity_of_energy_hydrogen_solar_pv_solar_radiation
  capacity_of_energy_hydrogen_steam_methane_reformer
  capacity_of_energy_hydrogen_autothermal_reformer
  capacity_of_energy_hydrogen_biomass_gasification
  capacity_of_energy_imported_hydrogen_baseload
  capacity_of_energy_hydrogen_flexibility_p2g_electricity
].freeze

namespace :hydrogen do
  desc "Computes scenario values for after deploy; saves to JSON"
  task dump: :environment do
    collected = 0
    data = {}

    Scenario.migratable.find_each.with_index do |scenario, index|
      next unless Atlas::Dataset.exists?(scenario.area_code)
      next unless INPUTS.any? { |key| scenario.user_values.key?(key) }

      collected += 1

      data[scenario.id] = {}
      gql = Inspect::LazyGql.new(scenario)

      data[scenario.id]['volume_of_energy_hydrogen_storage_salt_cavern'] = volume_of_energy_hydrogen_storage_salt_cavern(gql)

      # For testing purposes
      break if index >= 20

      if index.positive? && ((index + 1) % 1000).zero?
        say("#{index + 1} (#{collected} collected)")
      end
    end

    puts "Collected #{collected} results"

    filename = Rails.root.join("tmp/scenario_values.json")
    FileUtils.mkdir_p(filename.dirname)

    File.write(filename, JSON.dump(data))
  end
end

def volume_of_energy_hydrogen_storage_salt_cavern(gql)
  old_storage_volume = gql.query(
    'MAX(V(energy_hydrogen_storage,storage_curve))',
    nil,
    true
  ).future_value

  max_storage_volume = gql.query(
    'present:DIVIDE(Q(total_electricity_consumed),PRODUCT(MJ_PER_KWH,10**9))',
    nil,
    true
  ).first

  # Sometimes the storage curve does not work..
  if old_storage_volume
    [old_storage_volume, max_storage_volume].min
  else
    puts "Storage curve not found"
    max_storage_volume
  end
end
