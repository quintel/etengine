module Gql::UpdateInterface

class MarketShareCommand < CommandBase
  include ResponsibleByMatcher

  MATCHER = /^.*_market_share$/

  UPDATES = {
    :lighting_market_share => [
      'effective_lighting_demand_households_energetic',
      'traditional_lighting_households_energetic'
      ],
    :lighting_buildings_market_share => [
      'lighting_buildings_energetic',
      'tl5_buildings_energetic'
      ],
    :industry_heating_market_share => [
      'heating_demand_industry_energetic',
      'gas_burner_industry_industry_energetic'
      ],
    :heating_buildings_market_share => [
      'heating_buildings_energetic',
      'gas_fired_heater_buildings_energetic'
      ],
    :cooling_buildings_market_share => [
      'cooling_buildings_energetic',
      'airco_buildings_energetic'
      ],
    :agri_heating_market_share => [
      'heating_demand_agriculture_energetic',
      'gas_burner_agri_agriculture_energetic'
      ],
    :car_kms_market_share => [
      'cars_kms_demand_transport_energetic',
      'gasoline_cars_transport_energetic'
      ],
    :truck_kms_market_share => [
      'truck_kms_demand_transport_energetic',
      'diesel_trucks_transport_energetic'
    ]
  }

  attr_reader :parent_key, :flexible_key

  ##
  # param object [Qernel::Converter]
  #
  def initialize(object, attr_name, command_value)
    @object = object
    @attr_name = attr_name
    @command_value = command_value.to_f
    @parent_key, @flexible_key = UPDATES[@attr_name.to_sym]
  end

  # TODO refactor (seb 2010-10-11)
  def execute
    calculate_market_share
  end

  def calculate_market_share
    if child_link
      child_link.share = @command_value
      flexible_link.share = flexible_link_share
    end
  end

  def flexible_link_share
    [0.0, 1.0 - remaining_links.map(&:share).sum].max
  end

  def remaining_links
    (links - [flexible_link])
  end

  ##
  # @return [Qernel::Converter]
  #
  def parent
    child_link.parent
  end

  ##
  # @return [Array<Qernel::Converter>]
  #
  def links
    parent.input_links
  end

  ##
  # @return [Qernel::Converter]
  #
  def flexible_link
    links.detect{|l| l.child.full_key == flexible_key.to_sym}
  end

  ##
  # @return [Qernel::Converter]
  #
  def child_link
    @child_link ||= object.output_links.detect{|l| l.parent.full_key == parent_key.to_sym}
  end

  def self.create(graph, converter_proxy, key, value)
    new(converter_proxy.converter, key, value)
  end

end

end
