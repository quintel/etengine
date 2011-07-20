module Qernel

##
# A slot combines several input/output links of the same carrier.
# It can either be on the input or output side of a converter. A
# slot waits (see #ready?) until all passive_links have been calculated
# and then calculates the active_links.
#
# Usually we are just interested in the #external_value of a slot,
# which is the amount of energy that goes through. The internal value
# is the external_value * conversion, which in the end equals the converter
# demand. So:
#
#  external_value * conversion = internal_value = converter.demand
#
#
class Slot
  include DatasetAttributes

  attr_accessor :converter, :converter_id, :graph
  attr_reader :carrier, :direction, :id

  DATASET_ATTRIBUTES = [:conversion]
  dataset_accessors DATASET_ATTRIBUTES

  def initialize(id, converter, carrier, direction = :input)
    @id = id
    @converter = converter
    @carrier = carrier
    @direction = direction
    self.dataset_key # memoize dataset_key
  end

  # @return [Boolean] is Slot ready for calculation?
  #
  def ready?
    passive_links.all?(&:value)
    # 2010-06-07 sb:
    # Theoretically it should be:
    #
    #   passive_links.all?(&:value) and converter.has_demand?
    #
    # As a slot can only calculate if the converter demand is
    # known. But as we control the flow from the converter we
    # can skip this (saves a bit of performance).
  end


  # @return [Array<Link>]
  #
  def links
    # For legacy reasons, we still access links through the converter.
    @links ||= if input? 
      converter.input_links.select{|l| l.carrier == @carrier} 
    else
      converter.output_links.select{|l| l.carrier == @carrier}
    end
  end

  # Links that are calculated by this converter
  #
  # @return [Array<Link>]
  #
  def active_links
    @active_links ||= if input? 
      links.select(&:calculated_by_left?)
    else
      links.select(&:calculated_by_right?)
    end
  end

  # Links that are calculated by another converter
  #
  # If it is an input slot then:
  # * dependent?
  # * inversed_flexible?
  # * (constant? and share.nil?) # constant links that take the values from a converter
  #
  # @return [Array<Link>]
  #
  def passive_links
    @passive_links ||= if input? 
      links.select(&:calculated_by_right?) 
    else 
      links.select(&:calculated_by_left?)
    end
  end

  ##
  # Calculates the link values
  #
  def calculate
    # 2010-06-07 sb
    # I don't remember why I don't use active_links here.
    # I assume it must be because of inversed_flexible?
    # and [constant with undefined value].

    active_links.select(&:constant?).each(&:calculate)
    active_links.select(&:share?).each(&:calculate)
    active_links.select(&:flexible?).each(&:calculate)
    if output?
      links.select(&:dependent?).each(&:calculate)
    end
  end

  ##
  # @return [Float] Demand of Converter that the slot belongs to
  #
  def total_converter_demand
    converter.demand
  end

  ##
  # Expected value of this slot. Must equal to the actual value (sum of link values * conversion)
  # expected_demand = total_converter_demand * conversion
  #
  # @return [Float]
  #
  def expected_value
    conversion * (total_converter_demand || 0.0)
  end
  alias_method :expected_external_value, :expected_value

  ##
  # total demand of converter
  # value for converter
  #
  # @return [Float, nil] nil if not all links have values
  #
  def internal_value
    convert(external_value)
  end

  ##
  # value to the outside
  #
  # @return [Float, nil] nil if not all links have values
  #
  def external_value
    values = links.map(&:value)
    values.compact.sum.to_f
  end

  ##
  # Used for calculation of flexible links.
  #
  # @return [Float] Sum of link values
  #
  def external_passive_link_value
    links.reject(&:flexible?).map(&:value).compact.sum
  end

  ##
  # Used for calculation of inversed_flexible links.
  #
  # @return [Float] Sum of link values
  #
  def external_link_value
    links.map(&:value).compact.sum
  end

  ##
  # @unused
  #
  def internal_link_value
    convert(external_link_value)
  end

  ##
  # Is slot on the input side?
  #
  # @return [Boolean]
  #
  def input?
    (direction === :input)
  end

  def output?
    !input?
  end

  def environment?
    converter.environment?
  end

  def loss?
    carrier.loss?
  end

  ##
  # Converts a value using the conversion.
  # Used to calculate internal_values.
  #
  # @param value [Float] e.g. external_value
  #
  def convert(value)
    return nil if value.nil?
    (conversion == 0.0) ? 0.0 : value / conversion
  end

  ##
  # Conversion for given carrier.
  #
  # @param carrier [Symbol,Carrier]
  # @return [Float] The input conversion for the carrier, calculates #actual_conversion if #dynamic?
  # @return 0.0 if no conversion defined for carrier
  # @return 1.0 if converter is environment?
  #
  def conversion
    if environment?
      1.0
    else
      dataset_get(:conversion) || 0.0
    end
  end

  def inspect
    "slot_#{id}"
  end
end

end
