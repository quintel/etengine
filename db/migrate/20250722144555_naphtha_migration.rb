class NaphthaMigration < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  CHANGES = [
    # Normal energetic
    RelativeChange.new(
      input_oil: 'industry_chemicals_other_burner_crude_oil_share',
      input_naphtha: 'industry_chemicals_other_burner_naphtha_share',
    ),
    # Normal non-energetic
    RelativeChange.new(
      input_oil: 'industry_chemicals_other_crude_oil_non_energetic_share',
      input_naphtha: 'industry_chemicals_other_naphtha_non_energetic_share',
    ),
    # External coupling energetic
    RelativeChange.new(
      input_oil: 'external_coupling_industry_chemical_other_burner_crude_oil_share',
      input_naphtha: 'external_coupling_industry_chemical_other_burner_naphtha_share',
    ),
    # External coupling non-energetic
    RelativeChange.new(
      input_oil: 'external_coupling_industry_chemical_other_non_energetic_crude_oil_share',
      input_naphtha: 'external_coupling_industry_chemical_other_non_energetic_naphtha_share',
    )
  ].freeze


  RENAME = %w[fertilizers refineries other].to_h do |sector|
    [
      "external_coupling_energy_chemical_#{sector}_transformation_external_coupling_node_crude_oil_output_share",
      "external_coupling_energy_chemical_#{sector}_transformation_external_coupling_node_naphtha_output_share"
    ]
  end.freeze

  def up
    # Load up defaults from dumps!
    # old_defaults = load_stuff
    # new_defaults = load_stuff

    migrate_scenarios do |scenario|
      CHANGES.each do |change|
        next if change.skip?(scenario)

        change.set_new_values(
          scenario,
          old_defaults[scenario.area_code],
          new_defaults[scenario.area_code]
        )
      end
      RENAME.each do |old_input, new_input|
        scenario.user_values[new_input] = scenario.user_values.delete(old_input)
      end
    end
  end

  RelativeChange = Struct.new(:input_oil, :input_naphtha) do
    def skip?(scenario)
      !scenario.user_values.key?(input)
    end

    def set_new_values(scenario, old_defaults, new_defaults)
      if change = relative_change(scenario, old_defaults)
        # Relative change times the new default for both oil and naptha
        scenario.user_values[input_oil] = new_defaults[input_oil] * change
        scenario.user_values[input_naphtha] = new_defaults[input_naphtha] * change
      else
        # If change can't be calculated, set naphtha to zero, oil stays unchanged
        scenario.user_values[input_naphtha] = 0
      end
    end

    def relative_change(scenario, defaults)
      unless defaults[input_oil].zero?
        return scenario.user_values[input_oil] / defaults[input_oil]
      end
    end
  end
end
