module Gql

module UpdateInterface

  class Graph
    include Selecting

    attr_reader :graph, :gql

    def initialize(gql, graph)
      @gql = gql
      @graph = graph
    end

    def update_with(update_statements, skip_time_curves = false)
      if update_statements
        update_carriers(update_statements['carriers'])
        update_area_data(update_statements['area'])
        update_converters(update_statements['converters'])
      end
    end

    def update_area_data(area_data_updates)
      cmds = []
      area = graph.query.area
      area_data_updates.andand.each do |id, updates|
        updates.each do |key, value|
          cmds << CommandFactory.create(graph, area, key, value)
        end
      end
      execute_commands(cmds)
    end

    def update_carriers(carrier_updates)
      cmds = []
      carrier_updates.andand.each do |ids, updates|
        ids.split('_AND_').reject(&:blank?).each do |id|
          future = graph.carrier(id)
          next unless future 

          updates.each do |key,value|
            cmds << CommandFactory.create(graph, future, key, value)
          end
        end
      end
      execute_commands(cmds)
    end

    def update_converters(converter_updates)
      converter_updates.andand.each do |select_query, updates|
        next if select_query.blank?

        combined_links = updates.select{|key,value| key[/combined_input_link_share_to_(.*)/] }
        select(select_query.to_s, graph).each do |converter|

          combined_links.each do |key,value|
            ckey = key[/combined_input_link_share_to_(.*)/,1]
            total = combined_links.values.map(&:to_f).compact.sum
            if link = graph.converter(converter.full_key).output_links.first
              link.share = total.to_f
            end

            if child_link = converter.input_links.detect{|link| link.child.full_key.to_sym == ckey.to_sym}
              child_link.share = (total.to_f == 0.0) ? 0.0 : (value.to_f / total.to_f)
            end
          end

          updates.each do |key, value|
            value = value.to_f
            proxy = converter.proxy
            cmds = []

            # TODO seb migrate those keys into preset_demand in db
            if type = key[/^(decrease_total|decrease_rate|growth_rate|decrease_rate|growth_total)(.*)$/,1]
              key = "preset_demand_#{key}"
            end

            if "replacement_of_households_rate" == key
              cmds << update_replacement_of_households_rate(proxy, value)
            elsif c = CommandFactory.create(graph, proxy, key, value)
              cmds << c
            end
            execute_commands(cmds)
          end
        end
      end
    end


    # Complex code to refactor. Biggest problem is that we use both present and future graph.
    #
    def update_replacement_of_households_rate(proxy, value)
      cmds = []
      # DEBT: input keys has following. which is weird with the following line.
      #   heating_demand_with_current_insulation_households_energetic_AND_heating_new_houses_current_insulation_households_energetic
      return cmds if proxy.to_s != "heating_demand_with_current_insulation_households_energetic"

      households = graph.area.number_households # AREA(number_households)
      percentage_new = graph.area.percentage_of_new_houses # AREA(percentage_of_new_houses)

      # get the future demand, this is needed for the calculation to determin the total number of houses to be replaced

      old_houses_demand_cmd = AttributeCommand.new(proxy, :preset_demand, value, :decrease_rate)
      old_houses_demand = proxy.preset_demand


      demand_per_old_house = old_houses_demand / ((1 - (percentage_new/100.0)) * households)
      # calculate the diff in demand for old_houses
      households_to_replace = (old_houses_demand - old_houses_demand_cmd.value) / demand_per_old_house

      households_existing = households - households_to_replace

      new_house_converter = graph.converter("heating_new_houses_current_insulation_households_energetic")
      demand_per_new_house = new_house_converter.query.preset_demand / (percentage_new/100.0 * households)

      # the nr of extrahouses multiplied with their demand is added to the original demand
      new_houses_future_demand_value = new_house_converter.query.demand + (demand_per_new_house * households_to_replace)

      cmds << AttributeCommand.new(graph.area, :number_of_existing_households, households_existing, :value)

      cmds << old_houses_demand_cmd

      # Ugly Hack for an Ugly existing solution, DS Tue Feb 28 17:34:15 CET 2012
      cmds << AttributeCommand.new(new_house_converter, :preset_demand, new_houses_future_demand_value, :value)

      cmds
    end

    def demand_per_old_house(demand,percentage,number_households)
      demand / ((1 - (percentage/100)) * number_households)
    end

    def execute_commands(cmds)
      cmds.flatten.compact.each(&:execute)
    end

  end
  
end

end
  