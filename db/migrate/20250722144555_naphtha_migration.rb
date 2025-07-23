class NaphthaMigration < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  RelativeChange = Struct.new(:input_oil, :input_naphtha, :default_key, :naphtha_default_key) do
    def skip?(scenario)
      !scenario.user_values.key?(input_oil)
    end

    # Calculates and sets the inputs for crude oil and naphtha on the scenario.
    # Uses the old and new defaults (start values) of the inputs.
    def set_new_values(scenario, old_defaults, new_defaults)
      if change = relative_change(scenario, old_defaults)
        # If a change can be calculated: the inputs are set to the
        # relative change times the new default for both oil and naptha
        scenario.user_values[input_oil] = new_defaults[default_key] * change
        scenario.user_values[input_naphtha] = new_defaults[naphtha_default_key] * change
      else
        # If change can't be calculated, set naphtha to zero, oil stays
        # unchanged
        scenario.user_values[input_naphtha] = 0
      end
    end

    # Returns the relative change of the input, based on the old default
    # of the input, and what it was set to by the user
    def relative_change(scenario, defaults)
      unless defaults[default_key].zero?
        return scenario.user_values[input_oil] / defaults[default_key]
      end
    end
  end

  # Inputs that need to be recalculated when they were set by the user.
  CHANGES = [
    # Normal energetic
    RelativeChange.new(
      input_oil: 'industry_chemicals_other_burner_crude_oil_share',
      input_naphtha: 'industry_chemicals_other_burner_naphtha_share',
      default_key: 'industry_chemicals_other_burner_crude_oil_share',
      naphtha_default_key: 'industry_chemicals_other_burner_naphtha_share'
    ),
    # Normal non-energetic
    RelativeChange.new(
      input_oil: 'industry_chemicals_other_crude_oil_non_energetic_share',
      input_naphtha: 'industry_chemicals_other_naphtha_non_energetic_share',
      default_key: 'industry_useful_demand_for_chemical_other_crude_oil_non_energetic_share',
      naphtha_default_key: 'industry_useful_demand_for_chemical_other_naphtha_non_energetic_share'
    ),
    # External coupling energetic
    RelativeChange.new(
      input_oil: 'external_coupling_industry_chemical_other_burner_crude_oil_share',
      input_naphtha: 'external_coupling_industry_chemical_other_burner_naphtha_share',
      default_key: 'industry_chemicals_other_burner_crude_oil_share', # same start value
      naphtha_default_key: 'industry_chemicals_other_burner_naphtha_share'
    ),
    # External coupling non-energetic
    RelativeChange.new(
      input_oil: 'external_coupling_industry_chemical_other_non_energetic_crude_oil_share',
      input_naphtha: 'external_coupling_industry_chemical_other_non_energetic_naphtha_share',
      default_key: 'industry_useful_demand_for_chemical_other_crude_oil_non_energetic_share', # same start value
      naphtha_default_key: 'industry_useful_demand_for_chemical_other_naphtha_non_energetic_share'
    )
  ].freeze

  RENAME = %w[fertilizers refineries other].to_h do |sector|
    [
      "external_coupling_energy_chemical_#{sector}_transformation_external_coupling_node_crude_oil_output_share",
      "external_coupling_energy_chemical_#{sector}_transformation_external_coupling_node_naphtha_output_share"
    ]
  end.freeze

  def up
    # Load up defaults from dumps
    old_defaults = load_defaults('old')
    new_defaults = load_defaults('new')

    migrate_scenarios do |scenario|
      CHANGES.each do |change|
        next if change.skip?(scenario)
        # NOTE: Some datasets do not work yet on the naphtha branch, skip them
        next unless new_defaults.key?(scenario.area_code)

        change.set_new_values(
          scenario,
          old_defaults[scenario.area_code],
          new_defaults[scenario.area_code]
        )
      end
      RENAME.each do |old_input, new_input|
        if scenario.user_values.key?(old_input)
          scenario.user_values[new_input] = scenario.user_values.delete(old_input)
        end
      end
    end
  end

  def load_defaults(tag)
    JSON.load(File.read(
      Rails.root.join(
        "db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values_#{tag}.json"
      )
    ))
  end
end
