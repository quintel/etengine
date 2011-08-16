module Qernel

class Carrier
  include DatasetAttributes

  CO2_FCE_COMPONENTS = [
    :co2_conversion_per_mj,
    :co2_exploration_per_mj,
    :co2_extraction_per_mj,
    :co2_treatment_per_mj,
    :co2_transportation_per_mj,
    :co2_waste_treatment_per_mj
  ]

  DATASET_ATTRIBUTES = [
    # :co2_per_mj,
    :cost_per_mj,
    :sustainable,
    :typical_production_per_km2,
    :kg_per_liter,
    :mj_per_kg,
    :supply_chain_margin_per_mj,
    :oil_price_correlated_part_production_costs,

    *CO2_FCE_COMPONENTS
  ]

  attr_accessor :id, :key, :name, :graph, :infinite

  dataset_accessors DATASET_ATTRIBUTES

  attr_reader :electricity, :steam_hot_water, :loss
  alias electricity? electricity
  alias steam_hot_water? steam_hot_water
  alias loss? loss

  # @param id [int]
  # @param key [Symbol]
  # @param name [String]
  # @param infinite [Float]
  #
  def initialize(id,key,name,infinite)
    self.id = id

    self.key = key.andand.to_sym
    self.name = name
    self.infinite = infinite

    @loss = self.key === :loss
    @electricity = self.key === :electricity
    @steam_hot_water = self.key === :steam_hot_water

    self.dataset_key # memoize dataset_key 
  end

  def dataset
    graph && graph.dataset
  end

  # The effective total co2 emission that gets emitted from 
  # exploration until waste treatment. The user can change the
  # individual co2_xxx_per_mj only indirectly by specifying 
  # origin of country for a specific carrier.
  #
  # @return [Float] 
  #   The sum of CO2_FCE_COMPONENTS.
  #
  def co2_per_mj
    dataset_fetch(:co2_per_mj) do
      if Current.scenario.use_fce
        CO2_FCE_COMPONENTS.map do |key|
          self.send(key)
        end.compact.sum
      else
        co2_conversion_per_mj
      end
    end
  end

  def ==(other)
    if other.is_a?(Symbol)
      #Rails.logger.info('carrier === Symbol')
      self.key === other
    else
      #Rails.logger.info('carrier === Carrier')
      self.id == other.id
    end
  end

  def to_s
    "Carrier: #{key}"
  end

  def inspect
    "carrier"
  end

end

end
