module Qernel

class Carrier

  # ----- Dataset -------------------------------------------------------------

  include DatasetAttributes
  extend DatasetCurveAttributes

  DATASET_ATTRIBUTES = Atlas::Carrier.attribute_set.map(&:name)

  dataset_accessors DATASET_ATTRIBUTES

  # Public: An array describing the price of the carrier in each hour.
  dataset_accessors :cost_curve

  # Public: An array describing the total demand for electricity in each hour.
  # Set by the electricity merit order calcualtion.
  dataset_curve_reader :demand_curve

  # ----- Micro optimization --------------------------------------------------

  # attr_readers on instance variables are faster then anything else
  #  workaround we alias later, because it's easier to set the "?"s
  #
  # So create some getter/setters for the most commonly used carriers.
  # they are set in #initialize
  # For the others we create a method_missing.
  attr_reader :electricity, :steam_hot_water, :loss
  alias electricity? electricity
  alias steam_hot_water? steam_hot_water
  alias loss? loss

  # make Array#flatten fast
  attr_reader :to_ary

  # ----- /Micro optimization -------------------------------------------------

  attr_accessor :id, :key, :graph

  # @example
  #   Qernel::Carrier.new key: :electricity
  #
  def initialize(opts)
    @key      = opts[:key]&.to_sym
    @id       = @key

    # ----- Micro optimization --------------------

    @loss            = @key === :loss
    @electricity     = @key === :electricity
    @steam_hot_water = @key === :steam_hot_water

    self.dataset_key # memoize dataset_key
  end

  def dataset_group
    :carriers
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
    # can be overwritten by Fce plugin
    fetch(:co2_per_mj) { co2_conversion_per_mj }
  end

  def merit_order_co2_per_mj
    if @key == :gas_power_fuelmix
      graph.carrier(:natural_gas).co2_per_mj
    else
      co2_per_mj
    end
  end

  def merit_order_cost_per_mj
    if @key == :gas_power_fuelmix
      graph.carrier(:natural_gas).cost_per_mj
    else
      cost_per_mj || 0.0
    end
  end

  def cost_curve
    dataset_get(:cost_curve) || ([merit_order_cost_per_mj * 3600] * 8760)
  end

  # Public: Sets the fallback price of the carrier.
  #
  # This is used by Merit to calculate the price of electricity when no participant can set the
  # price; typically when all producers are running at full capacity. Attempting to set the fallback
  # price on any other carrier will raise an error.
  def fallback_price=(price)
    raise "Cannot set fallback_price on #{@key} carrier" unless electricity?

    dataset_set(:fallback_price, price)
  end

  def ==(other)
    return false if other.nil?
    if other.is_a?(Symbol)
      self.key === other
    else
      self.id == other.id
    end
  end

  # used by url_for
  def to_param
    key.to_s
  end

  def to_s
    inspect
  end

  def inspect
    "<Qernel::Carrier id:#{id} key:#{key}>"
  end

  def method_missing(name, args = nil)
    if name.to_s.include? "?"
      #   def biogas?
      #     carrier.key === :biogas
      #   end
      self.class_eval <<-EOF,__FILE__,__LINE__ +1
        def #{name}
          @key == #{name.to_s[0...-1].to_sym.inspect}
        end
      EOF
      self.send(name) # dont forget to return the value
    else
      super
    end
  end

end

end
