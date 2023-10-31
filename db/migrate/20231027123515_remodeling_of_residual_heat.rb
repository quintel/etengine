require 'etengine/scenario_migration'

class RemodelingOfResidualHeat < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  REPLACE_COUPLED_SHARES = {
    'external_coupling_industry_chemical_fertilizers_residual_heat_share' => %w[
      external_coupling_industry_chemical_fertilizers_residual_heat_processes_share
      external_coupling_industry_chemical_fertilizers_residual_heat_flue_gasses_share
    ],
    'external_coupling_industry_chemical_other_residual_heat_share' => %w[
      external_coupling_industry_chemical_other_residual_heat_processes_share
      external_coupling_industry_chemical_other_residual_heat_flue_gasses_share
    ],
    'external_coupling_industry_chemical_refineries_residual_heat_share' => %w[
      external_coupling_industry_chemical_refineries_residual_heat_processes_share
      external_coupling_industry_chemical_refineries_residual_heat_flue_gasses_share
    ]
  }

  DELETE_COUPLED_SLIDERS = %w[
    external_coupling_industry_chemical_fertilizers_residual_heat_wacc
    external_coupling_industry_chemical_fertilizers_residual_heat_technical_lifetime
    external_coupling_industry_chemical_fertilizers_residual_heat_fixed_om_costs
    external_coupling_industry_chemical_fertilizers_residual_heat_investment_costs
    external_coupling_industry_chemical_refineries_residual_heat_wacc
    external_coupling_industry_chemical_refineries_residual_heat_technical_lifetime
    external_coupling_industry_chemical_refineries_residual_heat_fixed_om_costs
    external_coupling_industry_chemical_refineries_residual_heat_investment_costs
    external_coupling_industry_chemical_other_residual_heat_wacc
    external_coupling_industry_chemical_other_residual_heat_technical_lifetime
    external_coupling_industry_chemical_other_residual_heat_fixed_om_costs
    external_coupling_industry_chemical_other_residual_heat_investment_costs
    external_coupling_industry_other_ict_residual_heat_wacc
    external_coupling_industry_other_ict_residual_heat_technical_lifetime
    external_coupling_industry_other_ict_residual_heat_fixed_om_costs
    external_coupling_industry_other_ict_residual_heat_investment_costs
  ]

  def up
    dataset_heat_values = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))

    migrate_scenarios do |scenario|
      # First calc new HT residual heat value, because it might need some of the old coupling inputs
      dataset_values = dataset_heat_values[scenario.area_code.to_s]
      calculate_new_ht_residual_heat(scenario, dataset_values)

      # Then replace and remove coupling inputs
      set_coupling_inputs(scenario)
    end
  end

  private

  # If the scenario was a coupled scenario, act on the coupling sliders.
  def set_coupling_inputs(scenario)
    return unless scenario.coupled?

    replace_coupled_shares(scenario)

    DELETE_COUPLED_SLIDERS.each { |key| scenario.user_values.delete(key) }
  end

  # Checks for each new share input if any of the old ones were set. If so, the new share will
  # be the sum of the old ones. The old ones are deleted.
  def replace_coupled_shares(scenario)
    REPLACE_COUPLED_SHARES.each do |new_key, old_keys|
      was_set = false

      new_share = old_keys.reduce(0.0) do |sum, old_key|
        was_set = true if scenario.user_values.key? old_key
        sum += scenario.user_values.delete(old_key) || 0
      end

      scenario.user_values[new_key] = new_share if was_set
    end
  end

  # Residual heat wordt nu ingesteld op basis van shares, bijvoorbeeld 50% van de beschikbaar
  # restwarmte in de ICT wordt ingezet. De nieuwe implementatie van restwarmte is absoluut,
  # bijvoorbeeld 10 PJ restwarmte wordt geleverd aan het HT-warmtenet.
  # When any of the residual heat shares was set, we should calculate the new volume and set
  # the new inputs
  def calculate_new_ht_residual_heat(scenario, dataset_values)
    # Check if the dataset is still available
    return unless dataset_values.present?
    # Check if any shares were set
    return unless should_calculate?(scenario)


    scenario.user_values['volume_of_ht_residual_heat'] =
      residual_heat_from_ict(scenario, dataset_values) +
      residual_heat_from_refineries(scenario, dataset_values) +
      residual_heat_from_chemical_other(scenario, dataset_values) +
      residual_heat_from_fertilizers(scenario, dataset_values)
  end

  # Check if any shares were set
  def should_calculate?(scenario)
    has_any_inputs?(
      scenario,
      'share_of_industry_other_ict_reused_residual_heat',
      'share_of_industry_chemicals_refineries_reused_residual_heat',
      'share_of_industry_chemicals_other_reused_residual_heat',
      'share_of_industry_chemicals_fertilizers_reused_residual_heat'
    )
  end

  #--- Main formula

  # Calculates the residual heat for a sector based on sector properties
  def residual_heat_for_sector(
    initial_demand, sector_size, sector_efficiency, used_residual_heat,
    available_share_residual_heat_1, available_share_residual_heat_2, end_year, start_year
  )

    (initial_demand / 1000) * # convert TJ
      (sector_size / 100) *
      (1 - (sector_efficiency / 100))**(end_year - start_year) *
      (available_share_residual_heat_1 + available_share_residual_heat_2) *
      (used_residual_heat / 100)
  end

  #--- ICT

  def residual_heat_from_ict(scenario, dataset_values)
    return 0 unless scenario.user_values.key? 'share_of_industry_other_ict_reused_residual_heat'
    return 0 if dataset_values['industry_useful_demand_for_other_ict_electricity'].zero?

    residual_heat_for_sector(
      dataset_values['industry_useful_demand_for_other_ict_electricity'], # initial_demand
      scenario.user_values['industry_useful_demand_for_other_ict'] || 100, # sector_size
      0, # sector_efficiency
      scenario.user_values['share_of_industry_other_ict_reused_residual_heat'], # used_residual_heat
      dataset_values['industry_useful_demand_for_other_ict_electricity_industry_other_ict_potential_residual_heat_from_servers_electricity_parent_share'],
      0,
      scenario.start_year,
      scenario.end_year
    )
  end

  #--- Refineries

  def residual_heat_from_refineries(scenario, dataset_values)
    return 0 unless scenario.user_values.key? 'share_of_industry_chemicals_refineries_reused_residual_heat'
    return 0 if dataset_values['industry_useful_demand_for_chemical_refineries_useable_heat'].zero?
    return residual_heat_from_refineries_external_coupling(scenario, dataset_values) if refineries_coupled?(scenario)

    residual_heat_for_sector(
      dataset_values['industry_useful_demand_for_chemical_refineries_useable_heat'], # initial_demand
      scenario.user_values['industry_useful_demand_for_chemical_refineries'] || 100, # sector_size
      scenario.user_values['industry_useful_demand_for_chemical_refineries_useable_heat_efficiency'] || 0, # sector_efficiency
      scenario.user_values['share_of_industry_chemicals_refineries_reused_residual_heat'], # used_residual_heat
      dataset_values['industry_useful_demand_for_chemical_refineries_useable_heat_industry_chemicals_refineries_processes_potential_residual_heat_parent_share'],
      dataset_values['industry_useful_demand_for_chemical_refineries_useable_heat_industry_chemicals_refineries_flue_gasses_potential_residual_heat_parent_share'],
      scenario.start_year,
      scenario.end_year
    )
  end

  def refineries_coupled?(scenario)
    has_all_inputs?(scenario,
      'external_coupling_industry_chemical_refineries_useable_heat',
      'external_coupling_industry_chemical_refineries_residual_heat_processes_share',
      'external_coupling_industry_chemical_refineries_residual_heat_flue_gasses_share'
    )
  end

  def residual_heat_from_refineries_external_coupling(scenario, dataset_values)
    residual_heat_for_sector(
      dataset_values['industry_useful_demand_for_chemical_refineries_useable_heat'], # initial_demand
      scenario.user_values['external_coupling_industry_chemical_refineries_useable_heat'] || 100, # sector_size
      0, # sector_efficiency
      scenario.user_values['share_of_industry_chemicals_refineries_reused_residual_heat'], # used_residual_heat
      scenario.user_values['external_coupling_industry_chemical_refineries_residual_heat_processes_share'],
      scenario.user_values['external_coupling_industry_chemical_refineries_residual_heat_flue_gasses_share'],
      scenario.start_year,
      scenario.end_year
    )
  end

  #--- Chemical Other

  def residual_heat_from_chemical_other(scenario, dataset_values)
    return 0 unless scenario.user_values.key? 'share_of_industry_chemicals_other_reused_residual_heat'
    return 0 if dataset_values['industry_useful_demand_for_chemical_other_useable_heat'].zero?
    return residual_heat_from_chemical_other_external_coupling(scenario, dataset_values) if chemical_other_coupled?(scenario)

    residual_heat_for_sector(
      dataset_values['industry_useful_demand_for_chemical_other_useable_heat'], # initial_demand
      scenario.user_values['industry_useful_demand_for_chemical_other'] || 100, # sector_size
      scenario.user_values['industry_useful_demand_for_chemical_other_useable_heat_efficiency'] || 0, # sector_efficiency
      scenario.user_values['share_of_industry_chemicals_other_reused_residual_heat'], # used_residual_heat
      dataset_values['industry_useful_demand_for_chemical_other_useable_heat_industry_chemicals_other_processes_potential_residual_heat_parent_share'],
      dataset_values['industry_useful_demand_for_chemical_other_useable_heat_industry_chemicals_other_flue_gasses_potential_residual_heat_parent_share'],
      scenario.start_year,
      scenario.end_year
    )
  end

  def chemical_other_coupled?(scenario)
    has_all_inputs?(scenario,
      'external_coupling_industry_chemical_other_useable_heat',
      'external_coupling_industry_chemical_other_residual_heat_processes_share',
      'external_coupling_industry_chemical_other_residual_heat_flue_gasses_share'
    )
  end

  def residual_heat_from_chemical_other_external_coupling(scenario, dataset_values)
    residual_heat_for_sector(
      dataset_values['industry_useful_demand_for_chemical_other_useable_heat'], # initial_demand
      scenario.user_values['external_coupling_industry_chemical_other_useable_heat'] || 100, # sector_size
      0, # sector_efficiency
      scenario.user_values['share_of_industry_chemicals_other_reused_residual_heat'], # used_residual_heat
      scenario.user_values['external_coupling_industry_chemical_other_residual_heat_processes_share'],
      scenario.user_values['external_coupling_industry_chemical_other_residual_heat_flue_gasses_share'],
      scenario.start_year,
      scenario.end_year
    )
  end

  #--- Fertilizers

  def residual_heat_from_fertilizers(scenario, dataset_values)
    return 0 unless scenario.user_values.key? 'share_of_industry_chemicals_fertilizers_reused_residual_heat'
    return 0 if dataset_values['industry_chemicals_fertilizers_production'].zero?
    return residual_heat_from_fertilizers_external_coupling(scenario, dataset_values) if fertilizers_coupled?(scenario)

    # Note MB: de sector efficiency grijpt niet direct aan op de
    # industry_chemicals_fertilizers_production node, dus hier kan een verschil ontstaan.
    # Dit moeten we denk ik maar voor lief nemen...
    residual_heat_for_sector(
      dataset_values['industry_chemicals_fertilizers_production'], # initial_demand
      scenario.user_values['industry_useful_demand_for_chemical_fertilizers'] || 100, # sector_size
      scenario.user_values['industry_useful_demand_for_chemical_fertilizers_useable_heat_efficiency'] || 0, # sector_efficiency
      scenario.user_values['share_of_industry_chemicals_fertilizers_reused_residual_heat'], # used_residual_heat
      dataset_values['industry_chemicals_fertilizers_production_industry_chemicals_fertilizers_processes_potential_residual_heat_parent_share'],
      dataset_values['industry_chemicals_fertilizers_production_industry_chemicals_fertilizers_flue_gasses_potential_residual_heat_parent_share'],
      scenario.start_year,
      scenario.end_year
    )
  end

  def fertilizers_coupled?(scenario)
    has_all_inputs?(scenario,
      'external_coupling_industry_chemical_fertilizers_total_excluding_electricity',
      'external_coupling_industry_chemical_fertilizers_residual_heat_processes_share',
      'external_coupling_industry_chemical_fertilizers_residual_heat_flue_gasses_share'
    )
  end

  def residual_heat_from_fertilizers_external_coupling(scenario, dataset_values)
    residual_heat_for_sector(
      dataset_values['industry_chemicals_fertilizers_production'], # initial_demand
      scenario.user_values['external_coupling_industry_chemical_fertilizers_total_excluding_electricity'] || 100, # sector_size
      0, # sector_efficiency
      scenario.user_values['share_of_industry_chemicals_fertilizers_reused_residual_heat'], # used_residual_heat
      scenario.user_values['external_coupling_industry_chemical_fertilizers_residual_heat_processes_share'],
      scenario.user_values['external_coupling_industry_chemical_fertilizers_residual_heat_flue_gasses_share'],
      scenario.start_year,
      scenario.end_year
    )
  end

  # ---

  def has_all_inputs?(scenario, *inputs)
    inputs.all? { |input| scenario.user_values.key? input }
  end

  def has_any_inputs?(scenario, *inputs)
    inputs.any? { |input| scenario.user_values.key? input }
  end
end
