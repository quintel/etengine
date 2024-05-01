require 'etengine/scenario_migration'

class UpdateHydrogenSlow < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  INPUTS = %w[
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
    external_coupling_energy_production_synthetic_kerosene_demand
    external_coupling_energy_production_synthetic_methanol_demand
    external_coupling_industry_chemical_fertilizers_burner_hydrogen_share
    external_coupling_industry_chemical_fertilizers_non_energetic_hydrogen_share
    external_coupling_industry_chemical_other_burner_hydrogen_share
    external_coupling_industry_chemical_other_non_energetic_hydrogen_share
    external_coupling_industry_chemical_refineries_burner_crude_oil_share
    external_coupling_industry_metal_steel_energetic_hydrogen_share
    external_coupling_industry_residual_hydrogen
  ].freeze

  SHARES = %w[
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
    households_heater_combined_hydrogen_share
    households_heater_hybrid_hydrogen_heatpump_air_water_electricity_share
    buildings_space_heater_combined_hydrogen_share
    buildings_space_heater_hybrid_hydrogen_heatpump_air_water_electricity_share
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
  ].freeze

  INPUTS_DONE = %w[
    volume_of_energy_hydrogen_storage_salt_cavern
    capacity_of_energy_hydrogen_storage_salt_cavern
  ].freeze

  # Calculates graph properties - can take hours
  def up
    migrate_scenarios do |scenario|
      # Check who have already migrated
      next if INPUTS_DONE.any? { |key| scenario.user_values.key?(key) }

      next unless Atlas::Dataset.exists?(scenario.area_code)
      next unless (
        INPUTS.any? { |key| scenario.user_values.key?(key) } ||
        SHARES.any? { |key| scenario.user_values.key?(key) && !scenario.user_values[key].zero? }
      )

      begin
        gql = Inspect::LazyGql.new(scenario)

        next unless Qernel::Plugins::Causality.enabled?(gql.future_graph)
      rescue ArgumentError
        next
      end

      # -- STORAGE --
      new_storage_volume = volume_of_energy_hydrogen_storage_salt_cavern(gql)
      scenario.user_values['volume_of_energy_hydrogen_storage_salt_cavern'] = new_storage_volume

      new_storage_capacity = capacity_of_energy_hydrogen_storage_salt_cavern(gql, new_storage_volume)
      scenario.user_values['capacity_of_energy_hydrogen_storage_salt_cavern'] = new_storage_capacity

      # -- IMPORT/EXPORT --

      scenario.user_values['capacity_of_energy_imported_hydrogen_baseload'] =
        (scenario.user_values['capacity_of_energy_imported_hydrogen_baseload'] || 0.0) +
        energy_imported_hydrogen_backup(gql)

      scenario.user_values['volume_of_baseload_export_hydrogen'] =
        (scenario.user_values['volume_of_baseload_export_hydrogen'] || 0.0) +
        energy_export_hydrogen_backup(gql)

    rescue Gql::CommandError
      next
    end
  end

  def volume_of_energy_hydrogen_storage_salt_cavern(gql)
    old_storage_volume = gql.query(
      'DIVIDE(MAX(V(energy_hydrogen_storage,storage_curve)),MILLIONS)',
      nil,
      true
    ).future_value

    max_storage_volume = gql.query(
      'present:DIVIDE(Q(total_electricity_consumed),PRODUCT(MJ_PER_KWH,10**9))',
      nil,
      true
    ).first

    [old_storage_volume, max_storage_volume].min
  end

  def capacity_of_energy_hydrogen_storage_salt_cavern(gql, new_volume)
    old_storage_input_capacity = gql.query(
      'MAX(V(energy_hydrogen_storage,hydrogen_input_curve))',
      nil,
      true
    ).future_value

    old_storage_ouput_capacity = gql.query(
      'MAX(V(energy_hydrogen_storage,hydrogen_output_curve))',
      nil,
      true
    ).future_value

    old_storage_capacity = [old_storage_input_capacity, old_storage_ouput_capacity].max

    # In new modelling should be:
    # max_storage_capacity = present:DIVIDE(
    #     V(energy_hydrogen_storage_salt_cavern,"storage.volume"),
    #     V(energy_hydrogen_storage_salt_cavern,"hydrogen_output_capacity")
    #   ) * 2.0
    # Values in new modelling:
    #   - storage.volume = 250000.0
    #   - hydrogen_output_capacity = 1000.0
    # (250000.0 / 1000.0) * 2 = 500.0
    max_storage_capacity = 500.0

    storage_capacity = new_volume.zero? ? 0.0 : (new_volume * 1e6) / old_storage_capacity
    [[storage_capacity, 1.0].max, max_storage_capacity].min
  end

  def energy_imported_hydrogen_backup(gql)
    old_import_capacity = gql.query(
      'V(energy_imported_hydrogen_backup,demand)/MJ_PER_MWH/8760',
      nil,
      true
    ).future_value

    max_import_capacity = gql.query(
      'present:MAX(500,DIVIDE(Q(total_gas_consumed),PRODUCT(V(energy_imported_hydrogen_baseload,full_load_hours),MJ_PER_MWH)))',
      nil,
      true
    ).first

    [old_import_capacity, max_import_capacity].min
  end

  def energy_export_hydrogen_backup(gql)
    old_export_volume = gql.query(
      'DIVIDE(V(energy_export_hydrogen_backup,demand),BILLIONS)',
      nil,
      true
    ).future_value

    max_export_volume = gql.query(
      'present:PRODUCT(2,DIVIDE(Q(total_gas_consumed),BILLIONS))',
      nil,
      true
    ).first

    [old_export_volume, max_export_volume].min
  end
end
