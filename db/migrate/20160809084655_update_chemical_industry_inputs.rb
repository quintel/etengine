class UpdateChemicalIndustryInputs < ActiveRecord::Migration
  class ValueFacade
    def initialize(scenario)
      @user_values     = scenario.user_values.dup.with_indifferent_access
      @balanced_values = scenario.balanced_values.dup.with_indifferent_access
      @changed         = false
    end

    def changed?
      @changed
    end

    def apply_to(scenario)
      scenario.user_values = @user_values
      scenario.balanced_values = @balanced_values
      scenario
    end

    def keys
      (@user_values.keys + @balanced_values.keys).map(&:to_sym)
    end

    def [](key)
      collection_for(key)[key]
    end

    def []=(key, value)
      @changed = true
      collection_for(key, @user_values)[key] = value
    end

    def delete(key)
      if keys.include?(key)
        @changed = true
        collection_for(key).delete(key)
      end
    end

    private

    def collection_for(key, fallback = {})
      if @user_values.key?(key)
        @user_values
      elsif @balanced_values.key?(key)
        @balanced_values
      else
        fallback
      end
    end
  end

  def up
    count   = Scenario.count
    before  = Time.now
    changed = 0

    Scenario.find_each.with_index do |scenario, index|
      if update_scenario!(scenario)
        changed += 1
      end

      if ((index+1) % 2000).zero?
        puts "Done #{ index+1 } of #{ count } (#{ Time.now - before}s, #{ changed } changes)"
        before = Time.now
        changed = 0
      end
    end
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end

  private

  def update_scenario!(scenario)
    return false if scenario.user_values.keys.any? { |k| k.is_a?(Numeric) }

    # Skip old scenarios which refer to regions for which we no longer have
    # a dataset.
    return false unless scenario.area_code && Atlas::Dataset.exists?(scenario.area_code)

    # before = Time.now
    values = ValueFacade.new(scenario)

    global_renames = {
      industry_burner_coal_share: [
        :industry_chemicals_refineries_burner_coal_share
      ],
      industry_burner_coal_share_present: [
        :industry_chemicals_refineries_burner_coal_share_present
      ],
      industry_burner_crude_oil_share: [
        :industry_chemicals_refineries_burner_crude_oil_share
      ],
      industry_burner_crude_oil_share_present: [
        :industry_chemicals_refineries_burner_crude_oil_share_present
      ],
      industry_burner_network_gas_share: [
        :industry_chemicals_refineries_burner_network_gas_share
      ],
      industry_burner_network_gas_share_present: [
        :industry_chemicals_refineries_burner_network_gas_share_present
      ],
      industry_burner_wood_pellets_share: [
        :industry_chemicals_refineries_burner_wood_pellets_share
      ],
      industry_burner_wood_pellets_share_present:	[
        :industry_chemicals_refineries_burner_wood_pellets_share_present
      ],
      industry_chemicals_burner_coal_share: [
        :industry_chemicals_other_burner_coal
      ],
      industry_chemicals_burner_coal_share_present: [
        :industry_chemicals_other_burner_coal_share_present
      ],
      industry_chemicals_burner_crude_oil_share: [
        :industry_chemicals_other_burner_crude_oil_share
      ],
      industry_chemicals_burner_crude_oil_share_present: [
        :industry_chemicals_other_burner_crude_oil_share_present
      ],
      industry_chemicals_burner_network_gas_share: [
        :industry_chemicals_other_burner_network_gas_share
      ],
      industry_chemicals_burner_network_gas_share_present: [
        :industry_chemicals_other_burner_network_gas_share_present
      ],
      industry_chemicals_burner_wood_pellets_share: [
        :industry_chemicals_other_burner_wood_pellets_share
      ],
      industry_chemicals_burner_wood_pellets_share_present: [
        :industry_chemicals_other_burner_wood_pellets_share_present
      ],
      industry_final_demand_for_chemical_steam_hot_water_share: [
        :industry_final_demand_for_chemical_other_steam_hot_water_share
      ],
      industry_final_demand_for_chemical_steam_hot_water_share_present: [
        :industry_final_demand_for_chemical_other_steam_hot_water_share_present
      ],
      industry_final_demand_steam_hot_water_share: [
        :industry_final_demand_for_chemical_refineries_steam_hot_water_share
      ],
      industry_final_demand_steam_hot_water_share_present: [
        :industry_final_demand_for_chemical_refineries_steam_hot_water_share_present
      ],
      industry_useful_demand_for_chemical_electricity_efficiency: [
        :industry_useful_demand_for_chemical_other_electricity_efficiency,
        :industry_useful_demand_for_chemical_refineries_electricity_efficiency
      ],
      industry_useful_demand_for_chemical_useable_heat_efficiency: [
        :industry_useful_demand_for_chemical_other_useable_heat_efficiency,
        :industry_useful_demand_for_chemical_refineries_useable_heat_efficiency
      ]
    }

    copy_inputs!(values, global_renames)

    update_per_year_to_per_scenario!(values, :industry_aluminium_production, scenario)
    update_per_year_to_per_scenario!(values, :industry_aluminium_production_both, scenario)
    update_per_year_to_per_scenario!(values, :industry_other_metals_production, scenario)
    update_per_year_to_per_scenario!(values, :industry_other_metals_production_both, scenario)
    update_per_year_to_per_scenario!(values, :industry_steel_production, scenario)
    update_per_year_to_per_scenario!(values, :industry_steel_production_both, scenario)

    # NL2013 Specific Changes
    # - - - - - - - - - - - -

    if scenario.area_code == 'nl'.freeze
      nl_renames = {
        industry_chemicals_burner_coal_share: [
          :industry_chemicals_fertilizers_burner_coal_share
        ],
        industry_chemicals_burner_coal_share_present: [
          :industry_chemicals_fertilizers_burner_coal_share_present
        ],
        industry_chemicals_burner_crude_oil_share: [
          :industry_chemicals_fertilizers_burner_crude_oil_share
        ],
        industry_chemicals_burner_crude_oil_share_present: [
          :industry_chemicals_fertilizers_burner_crude_oil_share_present
        ],
        industry_chemicals_burner_network_gas_share: [
          :industry_chemicals_fertilizers_burner_network_gas_share
        ],
        industry_chemicals_burner_network_gas_share_present: [
          :industry_chemicals_fertilizers_burner_network_gas_share_present
        ],
        industry_chemicals_burner_wood_pellets_share: [
          :industry_chemicals_fertilizers_burner_wood_pellets_share
        ],
        industry_chemicals_burner_wood_pellets_share_present: [
          :industry_chemicals_fertilizers_burner_wood_pellets_share_present
        ],
        industry_final_demand_for_chemical_steam_hot_water_share: [
          :industry_final_demand_for_chemical_fertilizers_steam_hot_water_share
        ],
        industry_final_demand_for_chemical_steam_hot_water_share_present: [
          :industry_final_demand_for_chemical_fertilizers_steam_hot_water_share_present
        ],
        industry_useful_demand_for_chemical_electricity_efficiency: [
          :industry_useful_demand_for_chemical_fertilizers_electricity_efficiency
        ],
        industry_useful_demand_for_chemical_useable_heat_efficiency: [
          :industry_useful_demand_for_chemical_fertilizers_useable_heat_efficiency
        ]
      }

      copy_inputs!(values, nl_renames)
    end

    # Grouped Input Changes
    # - - - - - - - - - - -

    # User inputs 1 to 5.

    value = group_summary(scenario, values, [
      :industry_useful_demand_for_chemical_crude_oil_non_energetic,
      :industry_useful_demand_for_chemical_electricity,
      :industry_useful_demand_for_chemical_network_gas_non_energetic,
      :industry_useful_demand_for_chemical_useable_heat,
      :industry_useful_demand_for_chemical_other_non_energetic
    ])

    if value
      if scenario.area_code == 'nl'.freeze
        values[:industry_useful_demand_for_chemical_fertilizers] = value
      end

      values[:industry_useful_demand_for_chemical_other] = value
      values[:industry_useful_demand_for_chemical_refineries] = value
    end

    # --

    # User inputs 6 - 10

    value = group_summary(scenario, values, [
      :industry_useful_demand_for_chemical_crude_oil_non_energetic_both,
      :industry_useful_demand_for_chemical_electricity_both,
      :industry_useful_demand_for_chemical_network_gas_non_energetic_both,
      :industry_useful_demand_for_chemical_other_non_energetic_both,
      :industry_useful_demand_for_chemical_useable_heat_both
    ])

    if value
      values[:industry_useful_demand_for_chemical_fertilizers_both] = value
      values[:industry_useful_demand_for_chemical_other_both] = value
      values[:industry_useful_demand_for_chemical_refineries_both] = value
    end

    # --

    # User inputs 11 - 14

    value = group_summary(scenario, values, [
      :industry_useful_demand_for_other_crude_oil_non_energetic,
      :industry_useful_demand_for_other_electricity,
      :industry_useful_demand_for_other_network_gas_non_energetic,
      :industry_useful_demand_for_other_useable_heat
    ])

    if value
      if scenario.area_code == 'nl'.freeze
        values[:industry_useful_demand_for_other_food] = value
        values[:industry_useful_demand_for_other_paper] = value
        values[:industry_useful_demand_for_other_aggregated_industry_nl] = value
      end

      values[:industry_useful_demand_for_other_aggregated_industry_other] = value
    end

    # --

    # User inputs 15 - 18

    value = group_summary(scenario, values, [
      :industry_useful_demand_for_other_crude_oil_non_energetic_both,
      :industry_useful_demand_for_other_electricity_both,
      :industry_useful_demand_for_other_network_gas_non_energetic_both,
      :industry_useful_demand_for_other_useable_heat_both
    ])

    if value
      if scenario.area_code == 'nl'.freeze
        values[:industry_useful_demand_for_other_food_both] = value
        values[:industry_useful_demand_for_other_paper_both] = value
        values[:industry_useful_demand_for_other_aggregated_industry_nl_both] = value
      end

      values[:industry_useful_demand_for_other_aggregated_industry_other_both] = value
    end

    # --

    value = inputs_average(values, [
      :industry_useful_demand_for_other_electricity_efficiency,
      :industry_useful_demand_for_other_useable_heat_efficiency
    ])

    if value
      if scenario.area_code == 'nl'.freeze
        values[:industry_useful_demand_for_other_food_efficiency] = value
        values[:industry_useful_demand_for_other_paper_efficiency] = value
        values[:industry_useful_demand_for_other_aggregated_industry_nl_efficiency] = value
      end

      values[:industry_useful_demand_for_other_aggregated_industry_other_efficiency] = value
    end

    # Delete Old Inputs
    # - - - - - - - - -

    [
      :industry_burner_coal_share,
      :industry_burner_coal_share_present,
      :industry_burner_crude_oil_share,
      :industry_burner_crude_oil_share_present,
      :industry_burner_network_gas_share,
      :industry_burner_network_gas_share_present,
      :industry_burner_wood_pellets_share,
      :industry_burner_wood_pellets_share_present,
      :industry_chemicals_burner_coal_share,
      :industry_chemicals_burner_coal_share_present,
      :industry_chemicals_burner_crude_oil_share,
      :industry_chemicals_burner_crude_oil_share_present,
      :industry_chemicals_burner_network_gas_share,
      :industry_chemicals_burner_network_gas_share_present,
      :industry_chemicals_burner_wood_pellets_share,
      :industry_chemicals_burner_wood_pellets_share_present,
      :industry_final_demand_for_chemical_steam_hot_water_share,
      :industry_final_demand_for_chemical_steam_hot_water_share_present,
      :industry_useful_demand_for_chemical_crude_oil_non_energetic,
      :industry_useful_demand_for_chemical_electricity,
      :industry_useful_demand_for_chemical_network_gas_non_energetic,
      :industry_useful_demand_for_chemical_crude_oil_non_energetic_both,
      :industry_useful_demand_for_chemical_electricity_both,
      :industry_useful_demand_for_chemical_network_gas_non_energetic_both,
      :industry_useful_demand_for_chemical_electricity_efficiency,
      :industry_useful_demand_for_chemical_useable_heat_efficiency,
      :industry_useful_demand_for_other_crude_oil_non_energetic,
      :industry_useful_demand_for_other_electricity,
      :industry_useful_demand_for_other_network_gas_non_energetic,
      :industry_useful_demand_for_other_useable_heat,
      :industry_useful_demand_for_other_crude_oil_non_energetic_both,
      :industry_useful_demand_for_other_electricity_both,
      :industry_useful_demand_for_other_network_gas_non_energetic_both,
      :industry_useful_demand_for_other_useable_heat_both,
      :industry_useful_demand_for_other_electricity_efficiency,
      :industry_useful_demand_for_other_useable_heat_efficiency,
      :industry_final_demand_steam_hot_water_share,
      :industry_useful_demand_for_chemical_useable_heat,
      :industry_useful_demand_for_chemical_other_non_energetic,
      :industry_final_demand_steam_hot_water_share_present,
      :industry_useful_demand_for_chemical_useable_heat_both,
      :industry_useful_demand_for_chemical_other_non_energetic_both
    ].each { |key| values.delete(key) }

    if values.changed?
      values.apply_to(scenario)
      scenario.save(validate: false)
    end

    values.changed?
  end

  def copy_inputs!(values, inputs)
    inputs.each do |from, to|
      next unless values[from]

      Array(to).each do |to_key|
        values[to_key] = values[from]
      end
    end
  end

  # Converts a %/y input value to a % when a value is already set for the given
  # key, otherwise nothing changes.
  def update_per_year_to_per_scenario!(values, key, scenario)
    if values[key]
      values[key] = per_year_to_per_scenario(values[key], scenario)
    end
  end

  # Converts a %/y input value to a %.
  def per_year_to_per_scenario(value, scenario)
    (1 + value.to_f / 100) ** (scenario.end_year - scenario.start_year) * 100
  end

  # Given a set of input keys, determines the average value of the inputs and
  # converts to a per-scenario factor.
  def group_summary(scenario, values, input_keys)
    avg = inputs_average(values, input_keys)
    return false unless avg

    per_year_to_per_scenario(avg, scenario)
  end

  # Given a set of input keys, determines the average value of the inputs.
  # Returns false if none of the inputs are set.
  def inputs_average(values, input_keys)
    return false if (values.keys & input_keys).empty?

    sum = input_keys.sum do |key|
      values[key] || 0.0 # Default value for all grouped inputs is zero.
    end

    sum / input_keys.length
  end
end
