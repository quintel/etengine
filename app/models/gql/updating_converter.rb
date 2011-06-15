module Gql
#
# == GQL Update of future graph
#
# All update statements are in a hash retrieved from Current.scenario.update_statements
#
# {'converters' => {
#     'gas_demand_industry_energetic' => {'growth_rate' => '0.01'} }
#   },
# 'carriers' => {
#     'electricity' => {
#       'cost_per_mj_growth_rate' => '0.01'
#     }
# }}
#
#
# == Updating Area data attributes
#
# Updateable attributes defined in Qernel::Area::ATTRIBUTES_USED
#
# {country_key => {'attribute_name_(value|growth)' => 'new_value'} }
#
# e.g.
# { 'nl' => {
#     'co2_price_growth_rate' => '0.01'
#     'co2_price_value' => '300.0'
# }}
#
#
# == Updating carrier attributes:
#
# {id_or_key => {'attribute_name_(value|growth)' => 'new_value'} }
#
# e.g.
# { 'electricity' => {
#     'cost_per_mj_growth_rate' => '0.01'
#     'co2_per_mj_value' => '300.0'
# }}
#
#
# == Converter attributes:
#
# preset demand: 'growth_rate' ('growth_year' is deprecated)
# e.g.
# { 'gas_demand_industry_energetic' => {'growth_rate' => '0.01'} }
#
#
# all attributes defined in Qernel::Calculator::ATTRIBUTES_USED
# {'key' => {'attribute_name_(growth_rate|value)' => 'value'}}
#
# e.g.
# {'key' => {
#    'co2_free_growth_rate' => 'value',
#    'construction_time_value' => 'value
#  }}
#
#
# == Converter Link shares:
#
# Needs a *_market_share method to define flexible links.
#
# {'key' => {'lighting_market_share' => 'value'}}
#
#
# == Converter Efficiency/Slot conversion:
#
# <carrier.key>_input_conversion_growth_rate
# <carrier.key>_output_conversion_growth_rate
#
# {'key' => {'heat_input_conversion_growth_rate' => 'value'}}
#
# == Converter output link share:
#
# If converter has *one* output link for a given carrier:
#
# <carrier.key>_output_link_share
#
# {'key' => {'heat_output_link_share' => 'new_share'}}
#
#
#
module UpdatingConverter
  def after_calculation_updates(graph)
    cmd = Update::AfterCalculationUpdate.new(graph)
    cmd.execute
  end


  ##
  # Update converters that have time_curves
  #
  def update_time_curves(graph)
    cmds = []
    graph.time_curves.andand.each do |converter_id, curve|
      if converter = graph.converter(converter_id)
        curve.each do |attr_name, curve|
          next if attr_name.nil?
          if Update::SlotConversionCommand.responsible?(attr_name)
            cmds << Update::SlotConversionCommand.new(converter, attr_name, curve[Current.scenario.end_year])
          else
            cmds << Update::AttributeCommand.new(converter.proxy, attr_name, curve[Current.scenario.end_year], 'value')
          end
        end
      end
    end
    execute_commands(cmds)
  end

  ##
  # Update policies
  #
  def update_policies(updates)
    updates.andand.each do |id, updates|
      # all policy related input_elements have attr_name = value
      policy.goal(id).user_value = updates['value'] if policy.goal(id)
    end
  end

  def update_area_data(graph, area_data_updates)
    cmds = []
    area = graph.query.area
    area_data_updates.andand.each do |id, updates|
      updates.each do |key, value|
        cmds << Update::CommandFactory.create(graph, area, key, value)
      end
    end
    execute_commands(cmds)
  end

  def update_carriers(graph, carrier_updates)
    cmds = []
    carrier_updates.andand.each do |ids, updates|
      ids.split('_AND_').reject(&:blank?).each do |id|
        future = graph.carrier(id)
        next unless future 

        updates.each do |key,value|
          cmds << Update::CommandFactory.create(graph, future, key, value)
        end
      end
    end
    execute_commands(cmds)
  end

  # Update:
  #   - converter_keys
  #   - attribute
  #   - value
  #   - value_type (:decrease, :total_growth, :growth_year, :value, ? really needed, could be interface responsibility)
  #   - scope (:general_growth, :efficiency)
  #   - factor (100, 1, 0.001)
  #
  #
  # {'id' => {
  #   'growth_rate' => '0.01',
  #   'decrease_rate' => '0.01',
  #   'lighting_market_share' => '0.01',
  #   'heating_market_share' => '0.01',
  #   '<carrier_key>_input_conversion_growth_rate => '0.01',
  #   '<carrier_key>_output_conversion_growth_rate => '0.01',
  #   '<calculator_attribute>_growth_rate => '0.01',
  #   '<calculator_attribute>_value => '100'
  # }}
  #
  def update_converters(graph, converter_updates)
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
            cmds << update_replacement_of_households_rate(graph, proxy, value)
          elsif key == "useable_heat_output_link_share" # key.match(Update::LinkShareCommand::MATCHER)
            # TODO: move to custom commands
            cmds << Update::CommandFactory.create(graph, proxy, key, value)
            if reverse_converter = future_converter(converter.full_key.to_s.gsub("heat_", "cold_"))
              cmds << Update::CommandFactory.create(graph, reverse_converter, "cooling_output_link_share", value)
            end
          elsif c = Update::CommandFactory.create(graph, proxy, key, value)
            cmds << c
          end

          execute_commands(cmds)
        end
      end
    end
  end


  ##
  # Complex code to refactor. Biggest problem is that we use both present and future graph.
  #
  def update_replacement_of_households_rate(graph, proxy, value)
    cmds = []
    return cmds if proxy.to_s != "heating_demand_with_current_insulation_households_energetic"

    nr_of_hh = graph.area.number_households
    perc_of_new_hh = graph.area.percentage_of_new_houses

    # get the future demand, this is needed for the calculation to determin the total number of houses to be replaced
    future_demand_old_houses_cmd = Update::AttributeCommand.new(proxy, :preset_demand, value, :decrease_rate)

    present_old_houses_demand = present_converter("heating_demand_with_current_insulation_households_energetic").proxy.preset_demand

    number_of_houses_to_replace = (present_old_houses_demand - future_demand_old_houses_cmd.value) / ## calculate the diff in demand for old_houses
                                  demand_per_old_house(present_old_houses_demand,perc_of_new_hh,nr_of_hh)
                                  
    number_of_existing_households = nr_of_hh - number_of_houses_to_replace

    new_house_converter = present_converter("heating_new_houses_current_insulation_households_energetic")
    demand_per_new_house = new_house_converter.query.preset_demand / (perc_of_new_hh * nr_of_hh)

    # the nr of extrahouses multiplied with their demand is added to the original demand
    new_houses_future_demand_value = new_house_converter.query.demand + (demand_per_new_house * number_of_houses_to_replace)

    cmds << Update::AttributeCommand.new(graph.area, :number_of_existing_households, number_of_existing_households, value)
    cmds << future_demand_old_houses_cmd
    cmds << Update::AttributeCommand.new(new_house_converter, :preset_demand, new_houses_future_demand_value, :value)

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
