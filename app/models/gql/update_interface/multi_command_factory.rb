module Gql::UpdateInterface

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
          link.share = converter.query.full_load_seconds * value.to_f
        end
      end
      nil
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

    def buildings_solarpanel_market_penetration
      return [] unless graph.query.potential_roof_pv_production_buildings

      c = graph.converter('solar_panels_buildings_energetic')
      constant_value = value.to_f * graph.query.potential_roof_pv_production_buildings
      [LinkShareCommand.create(graph, c, "electricity_output_link_share", constant_value)]
    end


    def self.responsible?(key)
      # TODO automate
      %w[
        buildings_solarpanel_market_penetration
        number_of_units
        number_of_heat_units
        production_in_mw
        constant_output_link_value
      ].include?(key.to_s)
    end

    def self.create(graph, converter_proxy, key, value)
      new(graph, converter_proxy, key, value)
    end

  end
end