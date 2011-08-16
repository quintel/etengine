module Gql::UpdateInterface

class MarketShareCarrierCommand < CommandBase
  include HasConverter
  include ResponsibleByMatcher

  MATCHER = /^(heating|cooling|cooking)_market_share$/

  UPDATES = {
    :heating_market_share => [
      'heating_demand_households_energetic',
      :useable_heat
      ],
    :cooking_market_share => [
      'cooking_demand_households_energetic',
      :useable_heat
      ],
    :cooling_market_share => [
      'cooling_demand_households_energetic',
      :cooling
     ]
  }

  attr_reader :graph, :parent_key, :carrier_key

  ##
  # param object [Qernel::Converter]
  #
  def initialize(graph, object, attr_name, command_value)
    super(object, attr_name, command_value)
    @graph = graph
    @parent_key, @carrier_key = UPDATES[@attr_name.to_sym]
  end

  def execute
    calculate_market_share_for_carrier
  end

  def calculate_market_share_for_carrier
    if child_link
      child_link.share = value
      rest = links.reject(&:flexible?).map(&:share).compact.sum
      flexible_link.share = 1.0 - rest
    end
  end

  def value
    @command_value
  end

  ##
  # @return [Qernel::Converter]
  #
  def parent
    graph.converter(parent_key)
  end

  ##
  # @return [Array<Qernel::Converter>]
  #
  def links
    parent.input(carrier_key.to_sym).links
  end

  ##
  # @return [Qernel::Converter]
  #
  def flexible_link
    links.detect(&:flexible?)
  end

  ##
  # @return [Qernel::Converter]
  #
  def child_link
    @child_link ||= links.detect{|l| l.child == converter}
  end

  def self.create(graph, converter_proxy, key, value)
    new(graph, converter_proxy.converter, key, value)
  end

end

end
