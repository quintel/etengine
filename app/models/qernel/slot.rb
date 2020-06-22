module Qernel

##
# A slot combines several input/output links of the same carrier.
# It can either be on the input or output side of a node. A
# slot waits (see #ready?) until all passive_links have been calculated
# and then calculates the active_links.
#
# Usually we are just interested in the #external_value of a slot,
# which is the amount of energy that goes through. The internal value
# is the external_value * conversion, which in the end equals the node
# demand. So:
#
#  external_value * conversion = internal_value = node.demand
#
#
class Slot
  include DatasetAttributes

  # Returns a new Slot instance.
  #
  # type      - The special-case "type" of slot to be used. For example,
  #             :elastic will give you a Slot::Elastic instance. nil will
  #             return a normal slot.
  # id        - Unique identifier for the slot.
  # node - The node to which the slot belongs.
  # carrier   - The carrier used by the links which connect to the slot.
  # direction - Indicates whether the slot is for :input or :output.
  #
  # Returns an instance of Slot, or a Slot subclass.
  #
  def self.factory(type, id, node, carrier, direction = :input)
    klass =
      case type
      when :loss       then Slot::Loss
      when :elastic    then Slot::Elastic
      when :link_based then Slot::LinkBased
      else                  Slot
      end

    klass.new(id, node, carrier, direction)
  end

  # --------- Accessor ---------------------------------------------------------

  attr_accessor :carrier,
                :node,
                :node_id,
                :graph

  attr_reader :direction,
              :id,
              :key


  # --------- Dataset ---------------------------------------------------------

  DATASET_ATTRIBUTES = [:conversion, :country_specific, :flexible, :reset_to_zero, :breakpoint]
  dataset_accessors DATASET_ATTRIBUTES

  def self.dataset_group; :graph; end

  # --------- Initialize ------------------------------------------------------

  def initialize(id, node, carrier, direction = :input)
    @id  = id.is_a?(Numeric) ? id : Hashpipe.hash(id)
    @key = @id
    @node = node
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
    #   passive_links.all?(&:value) and node.has_demand?
    #
    # As a slot can only calculate if the node demand is
    # known. But as we control the flow from the node we
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

    if input?
      active_links.select(&:constant?).each(&:calculate)
      active_links.select(&:share?).each(&:calculate)

      active_links.
        select(&:flexible?).
        # Sort by priority, higher numbers first.
        sort_by(&:priority).reverse.
        # Calculate edges with a max_demand first
        partition { |link| link.max_demand.present? }.
        flatten.each(&:calculate)
    end

    if output?
      links.select(&:reversed?).each(&:calculate)
      links.select(&:dependent?).each(&:calculate)
    end
  end

  # --------- Slot Types ------------------------------------------------------

  # @return [Boolean] Is Slot an input (on the left side of node)
  # Links that are calculated by this node
  #
  def input?
    (direction === :input)
  end

  # @return [Boolean] is it an output (on the left side of node)
  #
  def output?
    !input?
  end

  def environment?
    node.environment?
  end

  def loss?
    carrier.loss?
  end


  # --------- Traversal -------------------------------------------------------

  # @return [Array<Link>] Links that are calculated by this Slot
  #
  def active_links
    @active_links ||= if input?
      links.select(&Calculation::Links.method(:calculated_by_child?))
    else
      links.select(&Calculation::Links.method(:calculated_by_parent?))
    end
  end


  # @return [Array<Link>] Links calculated by the node on the other end.
  #
  def passive_links
    @passive_links ||= if input?
      links.select(&Calculation::Links.method(:calculated_by_parent?))
    else
      links.select(&Calculation::Links.method(:calculated_by_child?))
    end
  end

  # @return [Array<Link>]
  #
  def links
    # For legacy reasons, we still access links through the node.
    @links ||= if input?
      node.input_links.select{|l| l.carrier == @carrier}
    else
      node.output_links.select{|l| l.carrier == @carrier}
    end
  end

  def siblings
    if input?
      node.inputs - [self]
    else
      node.outputs - [self]
    end
  end

  # --------- Value -----------------------------------------------------------

  # Expected value of this slot. Must equal to the actual value (sum of link values * conversion)
  # expected_demand = total_node_demand * conversion
  #
  # @return [Float]
  #
  def expected_value
    conversion * (node.demand || 0.0)
  end
  alias_method :expected_external_value, :expected_value

  # total demand of node
  # value for node
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
    link_demand = links.map(&:value).compact.sum.to_f

    if has_reversed_shares?
      link_demand / reversed_share_compensation
    else
      link_demand
    end
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
  # @return 1.0 if node is environment?
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
  #     node_1
  #       node-(useable_heat): {flexible: true, conversion: null}
  #       node-(gas):  {conversion: 0.4}
  #
  #     node_1.input(:gas).flexible_conversion
  #     # => 0.6
  #
  # The conversion of the slot must be nil. otherwise {#conversion} will not delegate
  # to flexible_conversion.
  #
  def flexible_conversion
    if dataset_get(:flexible)
      if siblings.any?(&:flexible)
        raise "Multiple flexible slots defined for node: #{node.key}"
      end
      remainder = 1.0 - siblings.map(&:conversion).compact.sum
    else
      nil
    end
  end

  # --------- Reversed Shares -------------------------------------------------

  # Internal: Returns if the slot has any reversed share links.
  #
  # Returns true or false.
  def has_reversed_shares?
    if defined?(@has_reversed_shares)
      @has_reversed_shares
    else
      @has_reversed_shares = links.any? do |link|
        link.reversed? && link.link_type == :share
      end
    end
  end

  private :has_reversed_shares?

  # Internal: Determines by how much the external value needs to be adjusted in
  # order to account for uncalculated reversed share links.
  #
  # If the slot has a mix of forwards and reversed share links, the reversed
  # links aren't calculated until after the node demans is known. That is
  # too late, since the node demand won't account for the reversed
  # shares. Such slots require their external_value adjusting so that the
  # reversed shares are included.
  #
  # Returns a float.
  def reversed_share_compensation
    comp_share = links.reduce(0.0) do |comp, link|
      if link.reversed? && link.link_type == :share && link.value.nil?
        comp + link.share
      else
        comp
      end
    end

    comp_share >= 1.0 ? 1.0 : 1.0 - comp_share
  end

  private :reversed_share_compensation

  # --------- Debug -----------------------------------------------------------

  def inspect
    "<#{ self.class.name } id:#{ id } carrier:#{ carrier.key } " \
      "node:#{ node.key }>"
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
