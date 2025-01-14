require 'etengine/scenario_migration'

class RemoveExternalWtp < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  # All relevant building stock keys that could've been set
  EXTERNAL_WTP_KEYS = %w[
    external_coupling_industry_chemical_refineries_p2h_wtp
    external_coupling_industry_chemical_fertilizers_p2h_wtp
    external_coupling_industry_chemical_other_p2h_wtp
    external_coupling_industry_other_food_p2h_wtp
    external_coupling_industry_other_paper_p2h_wtp
  ].freeze

  REGULAR_WTP_KEYS = %w[
    wtp_of_industry_chemicals_refineries_flexibility_p2h_electricity
    wtp_of_industry_chemicals_fertilizers_flexibility_p2h_electricity
    wtp_of_industry_chemicals_other_flexibility_p2h_electricity
    wtp_of_industry_other_food_flexibility_p2h_electricity
    wtp_of_industry_other_paper_flexibility_p2h_electricity
]

  # Mapping of regular keys to external keys
  WTP_KEYS_MAPPING = {
    'wtp_of_industry_chemicals_refineries_flexibility_p2h_electricity' => 'external_coupling_industry_chemical_refineries_p2h_wtp',
    'wtp_of_industry_chemicals_fertilizers_flexibility_p2h_electricity' => 'external_coupling_industry_chemical_fertilizers_p2h_wtp',
    'wtp_of_industry_chemicals_other_flexibility_p2h_electricity' => 'external_coupling_industry_chemical_other_p2h_wtp',
    'wtp_of_industry_other_food_flexibility_p2h_electricity' => 'external_coupling_industry_other_food_p2h_wtp',
    'wtp_of_industry_other_paper_flexibility_p2h_electricity' => 'external_coupling_industry_other_paper_p2h_wtp'
  }.freeze


  def up

    migrate_scenarios do |scenario|
      # Check if one of external wtip sliders is touched, then some correction should be done to set keys
      next unless EXTERNAL_WTP_KEYS.any? { |key| scenario.user_values.key?(key)}
      set_regular_keys(scenario)
      remove_external_keys(scenario)
    end
  end

  def set_regular_keys(scenario)
    # Obtain old default area values

    WTP_KEYS_MAPPING.each do |regular_key, external_key|
      # Skip if key is not set in user_values
      next unless scenario.user_values.key?(external_key)

      # Retrieve the value from the external key
      value_to_transfer = scenario.user_values[external_key]

      # Set the corresponding regular key with the retrieved value
      scenario.user_values[regular_key] = value_to_transfer

      end
    end

    def remove_external_keys(scenario)
      EXTERNAL_WTP_KEYS.each do |external_key|
        # Remove the external key from user_values
        scenario.user_values.delete(external_key)
      end
    end
  end

