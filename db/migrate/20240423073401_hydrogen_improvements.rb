require 'etengine/scenario_migration'

class HydrogenImprovements < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  RENAME_CAPACITY_TO_MUST_RUN = {
    'capacity_of_energy_hydrogen_steam_methane_reformer' => 'capacity_of_energy_hydrogen_steam_methane_reformer_must_run',
    'share_of_energy_hydrogen_steam_methane_reformer_ccs' => 'share_of_energy_hydrogen_steam_methane_reformer_ccs_must_run',
    'capacity_of_energy_hydrogen_autothermal_reformer' => 'capacity_of_energy_hydrogen_autothermal_reformer_must_run',
    'share_of_energy_hydrogen_autothermal_reformer_ccs' => 'share_of_energy_hydrogen_autothermal_reformer_ccs_must_run',
    'capacity_of_energy_hydrogen_ammonia_reformer' => 'capacity_of_energy_hydrogen_ammonia_reformer_must_run'
  }.freeze

  CONVERT_WITH = {
    'capacity_of_energy_hydrogen_liquid_hydrogen_regasifier' =>  Atlas::EnergyNode.find('energy_hydrogen_liquid_hydrogen_regasifier').output[:hydrogen],
    'capacity_of_energy_hydrogen_lohc_reformer' =>  Atlas::EnergyNode.find('energy_hydrogen_lohc_reformer').output[:hydrogen]
  }.freeze

  SMR_ATR_BIOMASS = [
    { # SMR
      key: 'capacity_of_energy_hydrogen_steam_methane_reformer_must_run',
      share: 'share_of_energy_hydrogen_steam_methane_reformer_ccs_must_run',
      ccs_conversion:  Atlas::EnergyNode.find('energy_hydrogen_steam_methane_reformer_ccs_must_run').output[:hydrogen],
      non_ccs_conversion:  Atlas::EnergyNode.find('energy_hydrogen_steam_methane_reformer_must_run').output[:hydrogen]
    },
    { # ATR
      key: 'capacity_of_energy_hydrogen_autothermal_reformer_must_run',
      share: 'share_of_energy_hydrogen_autothermal_reformer_ccs_must_run',
      ccs_conversion:  Atlas::EnergyNode.find('energy_hydrogen_autothermal_reformer_ccs_must_run').output[:hydrogen],
      non_ccs_conversion:  Atlas::EnergyNode.find('energy_hydrogen_autothermal_reformer_must_run').output[:hydrogen]
    },
    { # BIOMASS
      key: 'capacity_of_energy_hydrogen_biomass_gasification',
      share: 'share_of_energy_hydrogen_biomass_gasification_ccs',
      ccs_conversion:  Atlas::EnergyNode.find('energy_hydrogen_biomass_gasification_ccs').output[:hydrogen],
      non_ccs_conversion:  Atlas::EnergyNode.find('energy_hydrogen_biomass_gasification').output[:hydrogen]
    }
  ].freeze

  WIND_AMMONIA_SOLAR = [
    { # Wind
      key: 'capacity_of_energy_hydrogen_wind_turbine_offshore',
      efficiency_key: 'efficiency_hydrogen_electrolysis',
      default_efficiency:  Atlas::EnergyNode.find('energy_hydrogen_electrolysis_wind_electricity').output[:hydrogen],
      area: nil
    },
    { # Amonia
      key: 'capacity_of_energy_hydrogen_ammonia_reformer_must_run',
      efficiency_key: 'efficiency_ammonia_reforming',
      default_efficiency:  Atlas::EnergyNode.find('energy_hydrogen_ammonia_reformer_must_run').output[:hydrogen],
      area: nil
    },
    { # Solar
      key: 'capacity_of_energy_hydrogen_solar_pv_solar_radiation',
      efficiency_key: 'efficiency_hydrogen_electrolysis',
      default_efficiency:  Atlas::EnergyNode.find('energy_hydrogen_electrolysis_solar_electricity').output[:hydrogen],
      area: 'hydrogen_electrolysis_solar_pv_capacity_ratio'
    }
  ].freeze

  RENAME_TRANSPORT = {
    'energy_transport_hydrogen_compressed_trucks_share' => 'energy_hydrogen_distribution_compressed_trucks_share',
    'energy_transport_hydrogen_pipelines_share' => 'energy_hydrogen_transport_pipelines_share'
  }.freeze

  def up
    migrate_scenarios do |scenario|
      # Voor alle technologieën waar een flexibele variant van is toegevoegd,
      # moet de waarde van de oude input overgezet worden naar de must-run input.
      rename_sliders(scenario, RENAME_CAPACITY_TO_MUST_RUN)

      migrate_production(scenario)

      rename_sliders(scenario, RENAME_TRANSPORT)
    end
  end

  private

  # Voor alle productietechnologieën zijn de inputs omgeschreven van
  # inputvermogen naar outputvermogen. Dit betekent dat ingestelde waardes
  # gemigreerd moeten worden op basis van de waterstofconversie-efficiëntie.
  def migrate_production(scenario)
    l2h_lohc(scenario)
    ccs_smr_atr_biomass(scenario)
    wind_ammonia_solar(scenario)
  end

  # --- Production ---

  def l2h_lohc(scenario)
    CONVERT_WITH.each do |key, conversion|
      if scenario.user_values.key?(key)
        scenario.user_values[key] = scenario.user_values[key] * conversion
      end
    end
  end

  def ccs_smr_atr_biomass(scenario)
    SMR_ATR_BIOMASS.each do |plant|
      next unless all_keys(scenario, plant[:key], plant[:share])

      total_input_capacity = scenario.user_values[plant[:key]]
      ccs_input_capacity = total_input_capacity * scenario.user_values[plant[:share]] / 100.0
      non_ccs_input_capacity = total_input_capacity * (1.0 - scenario.user_values[plant[:share]] / 100.0)

      ccs_output_capacity = ccs_input_capacity * plant[:ccs_conversion]
      non_ccs_output_capacity = non_ccs_input_capacity * plant[:non_ccs_conversion]

      total_output_capacity = ccs_output_capacity + non_ccs_output_capacity

      scenario.user_values[plant[:key]] = total_output_capacity
      scenario.user_values[plant[:share]] = ccs_output_capacity / total_output_capacity * 100.0
    end
  end

  def wind_ammonia_solar(scenario)
    WIND_AMMONIA_SOLAR.each do |plant|
      next unless scenario.user_values.key?(plant[:key])

      extra_factor = 1.0

      if plant[:area]
        next unless Atlas::Dataset.exists?(scenario.area_code)

        extra_factor = scenario.area[plant[:area]]
      end

      scenario.user_values[plant[:key]] =
        if scenario.user_values[plant[:efficiency_key]]
          scenario.user_values[plant[:key]] *
          extra_factor *
          scenario.user_values[plant[:efficiency_key]]
        else
          scenario.user_values[plant[:key]] *
          extra_factor *
          plant[:default_efficiency]
        end
    end
  end

  #--- Helpers ---

  def rename_sliders(scenario, renaming)
    renaming.each do |old_key, new_key|
      if scenario.user_values.key?(old_key)
        scenario.user_values[new_key] = scenario.user_values.delete(old_key)
      end
    end
  end

  def all_keys(scenario, *keys)
    keys.all? { |key| scenario.user_values.key? key }
  end
end
