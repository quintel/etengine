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

  # Returns a new Slot instance.
  #
  # @param [Symbol, nil] type
  #   The special-case "type" of slot to be used. For example, :elastic, will
  #   give you a Slot::Elastic. nil will return a normal Slot.
  # @param [Numeric] id
  #   Unique identifier for the slot.
  # @param [Qernel::Converter] converter
  #   The converter to which the slot belongs.
  # @param [Qernel::Carrier] carrier
  #   The carrier; indicates the type of links which connect to the slot.
  # @param [Symbol]
  #   Indicates whether the slot is for :input or :output.
  #
  # @return [Slot]
  #
  def self.factory(type, id, converter, carrier, direction = :input)
    klass = case type
      when :elastic           then Slot::Elastic
      when :carrier_efficient then Slot::CarrierEfficient
      else                         Slot
    end

    klass.new(id, converter, carrier, direction)
  end

  # --------- Accessor ---------------------------------------------------------

  attr_accessor :carrier,
                :converter,
                :converter_id,
                :graph

  attr_reader :direction,
              :id,
              :key


  # --------- Dataset ---------------------------------------------------------

  DATASET_ATTRIBUTES = [:conversion, :country_specific, :flexible, :reset_to_zero]
  dataset_accessors DATASET_ATTRIBUTES

  def self.dataset_group; :graph; end

  # --------- Initialize ------------------------------------------------------

  def initialize(id, converter, carrier, direction = :input)
    @id  = id.is_a?(Numeric) ? id : Hashpipe.hash(id)
    @key = @id
    @converter = converter
    @carrier   = carrier
    @direction = direction.to_sym
    self.dataset_key # memoize dataset_key
  end


  # --------- Calculation -----------------------------------------------------

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

  # Calculate the link values
  # @return [Array<Link>]
  #
  def calculate
    # 2010-06-07 sb
    # I don't remember why I don't use active_links here.
    # I assume it must be because of inversed_flexible?
    # and [constant with undefined value].

    if lft_of_converter?
      active_links.select(&:constant?).each(&:calculate)
      active_links.select(&:share?).each(&:calculate)

      # Calculate flexible links with boundaries first. Because
      # without boundaries a link takes everything.
      flexible_links = active_links.select(&:flexible?)
      flexible_links.select(&:max_boundaries?).sort_by(&:priority).each(&:calculate)
      flexible_links.reject(&:max_boundaries?).sort_by(&:priority).each(&:calculate)
    end
    if rgt_of_converter?
      links.select(&:reversed?).each(&:calculate)
      links.select(&:dependent?).each(&:calculate)
    end
  end


  # --------- Slot Types ------------------------------------------------------

  # @return [Boolean] Is Slot an input (on the left side of converter)
  # Links that are calculated by this converter
  #
  def input?
    (direction === :input)
  end
  alias_method :lft_of_converter?, :input?


  # @return [Boolean] is it an output (on the left side of converter)
  #
  def output?
    !input?
  end
  alias_method :rgt_of_converter?, :output?

  def environment?
    converter.environment?
  end

  def loss?
    carrier.loss?
  end


  # --------- Traversal -------------------------------------------------------

  # @return [Array<Link>] Links that are calculated by this Slot
  #
  def active_links
    @active_links ||= if lft_of_converter?
      links.select(&:calculated_by_left?)
    else
      links.select(&:calculated_by_right?)
    end
  end


  # @return [Array<Link>] Links calculated by the converter on the other end.
  #
  def passive_links
    @passive_links ||= if lft_of_converter?
      links.select(&:calculated_by_right?)
    else
      links.select(&:calculated_by_left?)
    end
  end

  # @return [Array<Link>]
  #
  def links
    # For legacy reasons, we still access links through the converter.
    @links ||= if lft_of_converter?
      converter.input_links.select{|l| l.carrier == @carrier}
    else
      converter.output_links.select{|l| l.carrier == @carrier}
    end
  end

  def siblings
    if input?
      converter.inputs - [self]
    else
      converter.outputs - [self]
    end
  end

  # --------- Value -----------------------------------------------------------

  # Expected value of this slot. Must equal to the actual value (sum of link values * conversion)
  # expected_demand = total_converter_demand * conversion
  #
  # @return [Float]
  #
  def expected_value
    conversion * (converter.demand || 0.0)
  end
  alias_method :expected_external_value, :expected_value

  # total demand of converter
  # value for converter
  #
  # @return [Float, nil] nil if not all links have values
  #
  def internal_value
    convert(external_value)
  end

  # Value to the outside
  #
  # @return [Float, nil] nil if not all links have values
  #
  def external_value
    values = links.map(&:value)
    values.compact.sum.to_f
  end

  # Used for calculation of flexible links.
  #
  # @return [Float] Sum of link values
  #
  def external_passive_link_value
    links.reject(&:flexible?).map(&:value).compact.sum
  end

  # Used for calculation of inversed_flexible links.
  #
  # @return [Float] Sum of link values
  #
  def external_link_value
    links.map(&:value).compact.sum
  end

  # Conversion for given carrier. Returns the conversion dataset attribute. If it is nil
  # and flexible, returns the remainder. Otherwise 0.0
  #
  # @param carrier [Symbol,Carrier]
  # @return [Float] The input conversion for the carrier, calculates #actual_conversion if #dynamic?
  # @return 0.0 if no conversion defined for carrier
  # @return 1.0 if converter is environment?
  #
  def conversion
    dataset_get(:conversion) || flexible_conversion || 0.0
  end

  # Converts a value using the conversion.
  # Used to calculate internal_values.
  #
  # @param value [Float] e.g. external_value
  #
  def convert(value)
    return nil if value.nil?
    (conversion == 0.0) ? 0.0 : value / conversion
  end

  # If a slot has a flag flexible: true we take the remainder of the other slots
  #
  # @example
  #     converter_1
  #       converter-(useable_heat): {flexible: true, conversion: null}
  #       converter-(gas):  {conversion: 0.4}
  #
  #     converter_1.input(:gas).flexible_conversion
  #     # => 0.6
  #
  # The conversion of the slot must be nil. otherwise {#conversion} will not delegate
  # to flexible_conversion.
  #
  def flexible_conversion
    if dataset_get(:flexible)
      if siblings.any?(&:flexible)
        raise "Multiple flexible slots defined for converter: #{converter.key}"
      end
      remainder = 1.0 - siblings.map(&:conversion).compact.sum
    else
      nil
    end
  end

  # --------- Debug -----------------------------------------------------------

  def inspect
    "<#{ self.class.name } id:#{ id } carrier:#{ carrier.key }>"
  end


  # TODO: find better names and explanation
  def kind
    case country_specific
    when 0 then :red
    when 1 then :yellow
    when 2 then :green
    end
  end

end

end
