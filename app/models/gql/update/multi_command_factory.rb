module Gql::Update

  ## 
  # For when a given update command requires more then one commands.
  # This are typically more complicate update commands. It's also
  # meant as a place for custom commands for which we need to use ruby.
  #
  class MultiCommandFactory

    attr_reader :graph, :converter_proxy, :key, :value

    def initialize(graph, converter_proxy, key, value)
      @graph = graph
      @converter_proxy = converter_proxy
      @key = key
      @value = value
    end

    def execute
      cmds.each(&:execute)
      cmds
    end

    def cmds
      [send(key)].flatten.compact
    end

    def rc_value
      min_level = 0.2
      saving_percentage = saving_percentage_for_rc_value(rc_value_present_value, min_level)
      LinkShareCommand.new(converter_proxy.converter, rc_value_link_name, saving_percentage)
    end

    def number_of_units_update
      converter = converter_proxy.converter
      converter_proxy.number_of_units = value.to_f

      converter.outputs.each do |slot|
        slot.links.select(&:constant?).each do |link|
          link.share = converter.query.production_based_on_number_of_units
        end
      end
      nil
    end
    alias number_of_units number_of_units_update 
    
    def number_of_heat_units_update
      converter = converter_proxy.converter
      converter_proxy.number_of_units = value.to_f

      converter.outputs.each do |slot|
        slot.links.select(&:constant?).each do |link|
          link.share = converter.query.production_based_on_number_of_heat_units
        end
      end
      nil
    end
    alias number_of_heat_units number_of_heat_units_update 
    
    ##
    # experimental
    def production_in_mw
      converter = converter_proxy.converter
      converter.outputs.each do |slot|
        slot.links.select(&:constant?).each do |link|
          link.share = converter.query.capacity_factor * value.to_f * SECS_PER_YEAR
        end
      end
      nil
    end
    
    ##
    # experimental
    def national_production_in_mw
      converter = converter_proxy.converter
      converter.preset_demand = converter.query.capacity_factor * value.to_f * SECS_PER_YEAR
      converter.outputs.each do |slot|
        slot.links.select(&:constant?).each do |link|
          link.share = converter.preset_demand + (converter.municipality_demand || 0)
        end
      end
      nil
    end
    
    def municipality_production_in_mw
      converter = converter_proxy.converter
      converter.municipality_demand = converter.query.capacity_factor * value.to_f * SECS_PER_YEAR
      converter.outputs.each do |slot|
        slot.links.select(&:constant?).each do |link|
          link.share = converter.municipality_demand + (converter.preset_demand || 0)
        end
      end
      nil
    end

    def om_growth_total
      [
        AttributeCommand.new(converter_proxy, :operation_and_maintenance_cost_fixed_per_mw_input, value, :growth_total),
        AttributeCommand.new(converter_proxy, :operation_and_maintenance_cost_variable_per_full_load_hour, value, :growth_total)
      ]
    end
    
    def cost_per_mj_oil_related_growth_total
      carrier = converter_proxy
      new_cost_per_mj = (1 + value) * 
        (carrier.cost_per_mj - carrier.supply_chain_margin_per_mj) * 
        carrier.oil_price_correlated_part_production_costs + 
        ( 1 - carrier.oil_price_correlated_part_production_costs) * 
        ( carrier.cost_per_mj - carrier.supply_chain_margin_per_mj ) + 
        carrier.supply_chain_margin_per_mj     
      AttributeCommand.new(carrier, :cost_per_mj, new_cost_per_mj, :value)
    end
    
    def ventilation_rate_buildings
      calculated_value = value / graph.query.area.ventilation_rate
      new_demand = calculated_value * converter_proxy.demand
      AttributeCommand.new(converter_proxy, :preset_demand, new_demand, :value)
    end
    
    def constant_output_link_value
      converter = converter_proxy.converter
      converter.outputs.each do |slot|
       slot.links.select(&:constant?).each do |link|
         link.share = value.to_f
       end
      end
      AttributeCommand.new(converter_proxy, :preset_demand, value.to_f, :value)
    end

    def solarpanel_market_penetration
      return [] unless graph.query.potential_roof_pv_production

      c = graph.converter('local_solar_pv_grid_connected_energy_energetic')
      constant_value = value.to_f * graph.query.potential_roof_pv_production
      [LinkShareCommand.create(graph, c, "electricity_output_link_share", constant_value)]
    end

    def buildings_solarpanel_market_penetration
      return [] unless graph.query.potential_roof_pv_production_buildings

      c = graph.converter('solar_panels_buildings_energetic')
      constant_value = value.to_f * graph.query.potential_roof_pv_production_buildings
      [LinkShareCommand.create(graph, c, "electricity_output_link_share", constant_value)]
    end


    def self.responsible?(key)
      # TODO automate
      %w[
        solarpanel_market_penetration
        buildings_solarpanel_market_penetration
        rc_value
        om_growth_total
        number_of_units
        number_of_heat_units
        ventilation_rate_buildings
        production_in_mw
        municipality_production_in_mw
        national_production_in_mw
        constant_output_link_value
        cost_per_mj_oil_related_growth_total
      ].include?(key.to_s)
    end

    def self.create(graph, converter_proxy, key, value)
      new(graph, converter_proxy, key, value)
    end

  private

    ##
    #
    #
    def rc_value_link_name
      direction = case converter_proxy.to_s
        when "extra_insulation_savings_households_energetic", "heating_savings_insulation_new_households_energetic"
          "output"
        when "heating_schools_current_insulation_buildings_energetic", "heating_offices_current_insulation_buildings_energetic"
          "input"
      end
      "useable_heat_#{direction}_link_share"
    end

    ##
    #
    #
    def rc_value_present_value
      graph_area_key = {
        'extra_insulation_savings_households_energetic' => :insulation_level_existing_houses,
        'heating_savings_insulation_new_households_energetic' => :insulation_level_new_houses,
        'heating_schools_current_insulation_buildings_energetic' => :insulation_level_schools,
        'heating_offices_current_insulation_buildings_energetic' => :insulation_level_offices
      }[converter_proxy.to_s]
      graph.area.send(graph_area_key)
    end

    def saving_percentage_for_rc_value(present_rc, min_level)
      # TOOD rob add brackets to clarify what behaviour ( / self.value + min_level or / (self.value + min_level))
      # (1 - ((1 - min_level) * present_rc / value + min_level))
      (1 - ((1 - min_level) * present_rc / @value + min_level))
    end
  end
end