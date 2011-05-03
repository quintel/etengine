module Qernel

class Carrier
  include DatasetAttributes

  CO2_LCE_COMPONENTS = [
    :co2_per_mj, # => :co2_conversion_per_mj
    :co2_exploration_per_mj,
    :co2_extraction_per_mj,
    :co2_treatment_per_mj,
    :co2_transportation_per_mj,
    :co2_waste_treatment_per_mj
  ]

  DATASET_ATTRIBUTES = [
    :cost_per_mj,
    :sustainable,
    :typical_production_per_km2,
    :kg_per_liter,
    :mj_per_kg,

    *CO2_LCE_COMPONENTS
  ]


  attr_accessor :id, :key, :name, :graph, :infinite

  dataset_accessors DATASET_ATTRIBUTES

  ##
  #
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
  end

  def dataset
    graph.dataset
  end

  def loss?
    key == :loss
  end

  # The effective total co2 emission that gets emitted from 
  # exploration until waste treatment. The user can change the
  # individual co2_xxx_per_mj only indirectly by specifying 
  # origin of country for a specific carrier.
  #
  # @return [Float] 
  #   The sum of CO2_LCE_COMPONENTS.
  #
  def co2_LCE_per_mj
    CO2_LCE_COMPONENTS.map do |key|
      self.send(key)
    end.compact.sum
  end

  def electricity?
    key == :electricity
  end

  def steam_hot_water?
    key == :steam_hot_water
  end

  def ==(other)
    if other.is_a?(Symbol)
      self.key == other
    else
      self.id == other.andand.id
    end
  end

  def to_s
    "Carrier: #{key}"
  end

end

end
