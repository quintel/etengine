require 'etengine/scenario_migration'

class InetQ4Inputs < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  AGRI_HEAT_GROUP = %i[
    agriculture_burner_crude_oil_share
    agriculture_burner_hydrogen_share
    agriculture_burner_network_gas_share
    agriculture_burner_wood_pellets_share
    agriculture_geothermal_share
    agriculture_heatpump_water_water_electricity_share
    agriculture_heatpump_water_water_ts_electricity_share
  ]

  AGRI_LOCAL_CHPS = %i[
    capacity_of_agriculture_chp_engine_biogas
    capacity_of_agriculture_chp_engine_network_gas_dispatchable
    capacity_of_agriculture_chp_engine_network_gas_must_run
    capacity_of_agriculture_chp_wood_pellets
  ].freeze

  ENERGY_CHPS = %i[
    capacity_of_energy_chp_local_engine_network_gas
    capacity_of_energy_chp_local_engine_biogas
    capacity_of_energy_chp_local_wood_pellets
  ].freeze

  def up
    default_values = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/defaults.json")
    ))

    migrate_scenarios do |scenario|
      defaults = default_values[scenario.area_code.to_s]

      next unless defaults.present?

      # Agriculture heating technology inputs
      # -------------------------------------

      # - Set agriculture_final_demand_local_steam_hot_water_share to 0.0
      scenario.user_values[:agriculture_final_demand_local_steam_hot_water_share] = 0.0

      # - Set agriculture_final_demand_central_steam_hot_water_share to the current value of
      #   agriculture_final_demand_steam_hot_water_share
      #
      # - Remove agriculture_final_demand_steam_hot_water_share from inputs
      scenario.user_values[:agriculture_final_demand_central_steam_hot_water_share] =
        scenario.user_values.delete(:agriculture_final_demand_steam_hot_water_share) ||
        defaults['agriculture_final_demand_steam_hot_water_share']

      # - Set all remaining inputs in the share_group = agri_heat to the current value
      #
      # If any of the inputs in the group are set, leave the values as they are, otherwise set
      # them to the values exported from production.
      unless AGRI_HEAT_GROUP.any? { |key| scenario.user_values.key?(key) }
        AGRI_HEAT_GROUP.each do |key|
          scenario.user_values[key] = defaults[key.to_s]

          # Remove any auto-set value for the input.
          scenario.balanced_values.delete(key)
        end
      end

      # Agriculture local CHP inputs
      # ---------------------------

      # - Set all inputs to 0.0
      AGRI_LOCAL_CHPS.each do |key|
        scenario.user_values[key] = 0.0
      end

      # Energy CHPs
      # -----------

      # - Set all inputs to the current value
      #
      # If the input already has a value, leave it as is, otherwise set them to the values exported
      # from production.
      ENERGY_CHPS.each do |key|
        scenario.user_values[key] ||= defaults[key.to_s]
      end
    end
  end
end
