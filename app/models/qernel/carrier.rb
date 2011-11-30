module Qernel

class Carrier
  include Topology::Carrier

  # ----- Dataset -------------------------------------------------------------

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
    :cost_per_mj,
    :sustainable,
    :typical_production_per_km2,
    :kg_per_liter,
    :mj_per_kg,
    :supply_chain_margin_per_mj,
    :oil_price_correlated_part_production_costs,
    :infinite, # infinite getter is overwritten below for legacy reason. 
    *CO2_FCE_COMPONENTS
  ]

  dataset_accessors DATASET_ATTRIBUTES


  # ----- Micro optimization --------------------------------------------------

  # attr_readers on instance variables are faster then anything else
  #  workaround we alias later, because it's easier to set the "?"s
  attr_reader :electricity, :steam_hot_water, :loss
  alias electricity? electricity #for performance optimization
  alias steam_hot_water? steam_hot_water #for performance optimization
  alias loss? loss #for performance optimization

  # ----- /Micro optimization -------------------------------------------------

  attr_accessor :id, :key, :graph

  # @param id [int]
  # @param key [Symbol]
  # @param infinite [Float]
  #
  def initialize(opts)
    @key      = opts[:key].andand.to_sym
    @id       = opts[:id] || self.key
    @infinite = opts[:infinite]

    # ----- Micro optimization --------------------
    @loss            = @key === :loss
    @electricity     = @key === :electricity
    @steam_hot_water = @key === :steam_hot_water

    self.dataset_key # memoize dataset_key 
  end

  def infinite
    # temporarly check whether infinite comes from the qernel::carrier 
    # if not available it's inside the dataset.
    @infinite || dataset_get(:infinite)
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
      # DEBT remove call to Current.scenario. add use_fce variable to graph dataset
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
      self.key === other
    else
      self.id == other.id
    end
  end

  def to_s
    inspect
  end

  def inspect
    "<Qernel::Carrier id:#{id} key:#{key}>"
  end

end

end
