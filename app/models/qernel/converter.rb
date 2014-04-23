module Qernel

##
# == demand and preset_demand
#
# preset_demand differs from demand, in that it's not changed by
# the calculation. This way we can access if a converter is assigned
# a demand or not.
#
# Assigning preset_demand will also assign the same value to demand.
# BUT as values are lazy-requested through dataset_attribute we have
# to make sure that in the dataset the :preset_demand is also copied
# to :demand
#
# e.g.
#   {:preset_demand => 1}
#   dataset_get(:preset_demand) # => 1
#   dataset_get(:demand) # => nil
#
#   {:preset_demand => 1, :demand => 1}
#   dataset_get(:preset_demand) # => 1
#   dataset_get(:demand) # => 1
#
# We do this in ConverterData < ActiveRecord::Base
#
# Also note that some update statements modify preset_demand, rather then
# demand.
#
# = Naming of child/parent converters and their links
#
# <tt>[Demander <b>D</b>]  <---Link <b>L</b> --- [Supplyer <b>S</b>]</tt>
#
# * Energy flows from S to D.
# * D demands energy from S
#
# * D is parent of S
# * D has a input_link(/downstream/supplying) Link L.
#
# * S is child of D
# * S has an output_link(upstream/demanding_link) link L to D
#
# * If link L is share, flexible or constant, D assigns a value to L
# * If link L is dependent, S assigns a value to L.
#
#
# * <tt>c.input_links = c.input_links</tt>
# * <tt>c.output_links = c.output_links</tt>
#
#
# Converter is ready? to fill own demand:
#
# Converter is ready to assign depending_demand_link_value if:
# - <tt>output_links.reject(&:depending?).all?(&:value)</tt>
# Special Case: output_links.reject(&:depending?).empty? and input_links.select(&:depending?).present?
#
#
#
# depending_demand_link_value = SUM(fixed & flexible output links) - SUM(dependent_input_links)
#
# If demand is set, assign supplying demanding link
#
class Converter
  extend ActiveModel::Naming

  include Qernel::RecursiveFactor::Base
  include Qernel::RecursiveFactor::PrimaryDemand
  include Qernel::RecursiveFactor::DependentSupply
  include Qernel::RecursiveFactor::FinalDemand
  include Qernel::RecursiveFactor::PrimaryCo2
  include Qernel::RecursiveFactor::WeightedCarrier
  include Qernel::RecursiveFactor::Sustainable

  include Qernel::RecursiveFactor::MaxDemand

  include DatasetAttributes

  attr_reader  :id,
               :output_links,
               :input_links,
               :groups,
               :sector_key,
               :use_key

  attr_accessor :converter_api, :key, :graph

  # The API type used by the converter.
  #
  # @return [Symbol]
  #   Returns which API type is used when performing calculations. Either
  #   :default or :demand_driven
  #
  attr_reader :type

  alias_method :lft_links, :output_links
  alias_method :rgt_links, :input_links

  dataset_accessors [:demand, :preset_demand, :excel_id]

  # --------- Micro-optimizing ------------------------------------------------
  #
  # This is really just for micro-optimizing code
  # as attr_readers are faster then normal method calls.
  attr_reader :sector_environment
  alias sector_environment? sector_environment

  attr_reader :primary_energy_demand, :useful_demand, :final_demand_group, :non_energetic_use, :energy_import_export
  alias primary_energy_demand? primary_energy_demand
  alias useful_demand? useful_demand
  alias final_demand_group? final_demand_group
  alias non_energetic_use? non_energetic_use
  alias energy_import_export? energy_import_export

  # --------- Initializing ----------------------------------------------------

  # @example Initialize a new converter
  #   Qernel::Converter.new(key: 'foo')
  #
  def initialize(opts)
    if !(opts.include?(:id) || opts.include?(:key))
      raise ArgumentError.new("Either :id or :key has to be passed to Qernel::Converter.new")
    end

    @id         = opts[:id] || Hashpipe.hash(opts[:key])
    @key        = opts[:key]
    @groups     = opts[:groups] || []
    @use_key    = opts[:use_id]
    @sector_key = opts[:sector_id]

    @output_links, @input_links = [], []
    @output_hash, @input_hash = {}, {}

    memoize_for_cache

    self.converter_api = Qernel::ConverterApi.for_converter(self)

    @calculation_state = :initialized
  end

  # return the excel id as a symbol for the graph#converter_lookup_hash
  # return the key if no excel_id defined or dataset not initialised yet.
  #
  def excel_id_to_sym
    if dataset_attributes
      (excel_id || key).to_s.to_sym
    else
      key
    end
  end

protected

  # Memoize here, so it doesn't have to at runtime
  #
  def memoize_for_cache
    @sector_environment    = sector_key === :environment

    @primary_energy_demand = @groups.include? :primary_energy_demand
    @useful_demand         = @groups.include? :useful_demand
    @final_demand_group      = @groups.include? :final_demand_group
    @non_energetic_use     = @groups.include? :non_energetic_use
    @energy_import_export  = @groups.include? :energy_import_export

    self.dataset_key # memoize dataset_key
  end

public
  def self.dataset_group; :graph; end

  # Set the graph so that we can access other  parts.
  #
  def graph=(graph)
    @graph = graph
    self.converter_api.graph = @graph
    self.converter_api.area = @graph.area
    @graph
  end

  # if demand is not set, use preset_demand.
  def demand
    fetch(:demand) { preset_demand }
    # equivalent to:
    # dataset_get(:demand) or dataset_set(:demand, preset_demand)
  end

  # Just calling to_f, would give wrong results nil.to_f => 0.0
  # But we also want to convert it to a float in case its an int.
  #
  # @param [Float, nil]
  # @return [Float, nil]
  #
  def safe_to_f(val)
    val.nil? ? nil : val.to_f
  end


  # --------- Building --------------------------------------------------------

  # @param link [Link]
  #
  def add_output_link(link)
    @output_links << link
  end

  # @param link [Link]
  #
  def add_input_link(link)
    @input_links << link
  end

  # @param slot [Qernel::Slot]
  # @return [Qernel::Slot]
  #
  def add_slot(slot)
    slot.converter = self

    # carrier_key can be either a {Symbol} or a {Qernel::Carrier}
    carrier_key = slot.carrier.key if slot.carrier.respond_to?(:key)
    if slot.input?
      @input_hash.merge! carrier_key => slot
    end

    if slot.output?
      @output_hash.merge! carrier_key => slot
    end
    reset_memoized_slot_methods
    slot
  end


  # --------- Traversal -------------------------------------------------------

  # typically loops contain an inversed_flexible (left) and a flexible (rgt) to
  # the same converter, and helps to only have positive energy flows.
  def has_loop?
    # if lft_converters and children have one converter in common it is a loop
    (lft_converters & rgt_converters).length > 0
  end

  # @return [Array<Converter>] Converters to the right
  #
  def rgt_converters
    @rgt_converters ||= input_links.map(&:rgt_converter)
  end

  # @return [Array<Converter>] Converters to the left
  #
  def lft_converters
    @lft_converters ||= output_links.map(&:lft_converter)
  end

  # @return [Array<Slot>] all input slots
  #
  def inputs
    @inputs ||= input_hash.values
  end

  alias_method :input_slots, :inputs

  # @return [Array<Slot>] all output slots
  #
  def outputs
    @outputs ||= output_hash.values
  end

  alias_method :output_slots, :outputs

  # @return [Array<Slot>] input *and* output slots
  #
  def slots
    @_slots ||= [*inputs, *outputs]
  end

  # Returns the input slot for the given carrier (key or object).
  #
  # e.g.
  # converter.input(:electricity)
  # => <Slot>
  #
  # @param carrier [Symbol,Carrier] the carrier key
  # @return [Slot]
  #
  def input(carrier = nil)
    carrier = carrier.key if carrier.respond_to?(:key)
    input_hash[carrier]
  end

  # Returns the output slot for the given carrier (key or object).
  #
  # e.g.
  # converter.output(:electricity)
  # => <Slot>
  #
  # @param carrier [Symbol,Carrier] the carrier key
  # @return [Slot]
  #
  def output(carrier = nil)
    carrier = carrier.key if carrier.respond_to?(:key)
    output_hash[carrier]
  end

protected

  # Hash of input slots, with the carrier keys as keys and slots as values
  # e.g.
  # { :loss => <Slot> }
  #
  # @return [Hash]
  #
  def input_hash
    @input_hash
  end

  # Hash of output slots, with the carrier keys as keys and slots as values
  # e.g.
  # { :loss => <Slot> }
  #
  # @return [Hash]
  #
  def output_hash
    @output_hash
  end

  def reset_memoized_slot_methods
    @inputs = nil
    @outputs = nil
    @_slots = nil
  end


  # --------- Calculations ----------------------------------------------------

public

  # Can the converters demand be calculated?
  #
  # @return [true,false]
  #
  def ready?
    slots.all?(&:ready?)
  end

  # Calculates the demand of the converter and of the links that depend on this demand.
  #
  # == Algorithm
  #
  # 1. (unless preset_demand is set) Sums demand of output_links (without dependent links) links.
  #
  # @pre converter must be #ready?
  #
  def calculate
    @calculation_state = :calculate

    # Constant links are treated differently.
    # They can overwrite the preset_demand of this converter
    output_links.select(&:constant?).each(&:calculate)

    # this is an attempt to solve this issue
    # https://github.com/dennisschoenmakers/etengine/issues/258
    input_links.select(&:constant?).each(&:calculate) if output_links.any?(&:inversed_flexible?)

    # If the demand is already set (is not nil), do not overwrite it.
    if self.demand.nil?
      self.demand ||= update_demand
    end # Demand is set
    @calculation_state = :calculating_after_update_demand

    # Now calculate the slots of this converter
    slots.each(&:calculate)

    # inversed_flexible fills up the difference of the calculated input/output slot.
    output_links.select(&:inversed_flexible?).each(&:calculate)
  end

protected

  # The highest internal_value of in/output slots is the demand of
  # this converter. If there are slots with different internal_values
  # they have to update their passive links, (this happens in #calculate).
  #
  # @pre converter must be #ready?
  # @pre has to be used from within #calculate, as slots have to be adjusted
  #
  # @return [Float] The demand of this converter
  #
  def update_demand
    if output_links.any?(&:inversed_flexible?) or output_links.any?(&:reversed?)
      @calculation_state = :update_demand_if_inversed_flexible_or_reversed
      slots.map(&:internal_value).compact.max
    elsif output_links.empty?
      @calculation_state = :update_demand_if_no_output_links
      # 2010-06-23: If there is no output links we take the highest value from input.
      # otherwise left dead end converters don't get values
      inputs.map(&:internal_value).compact.max
    else
      @calculation_state = :update_demand
      # 2010-06-23: The normal case. Just take the highest value from outputs.
      # We did this to make the gas_extraction gas_import_export thing work
      outputs.map(&:internal_value).compact.max
    end
  end

  # --------- Carriers --------------------------------------------------------

public

  # @return [Array<Carrier>] Carriers of input
  #
  def input_carriers; input_links.map(&:carrier).compact; end

  # @return [Array<Carrier>] Carriers of output
  #
  def output_carriers; output_links.map(&:carrier).compact; end


  # --------- Loss ------------------------------------------------------------

  # @return [Float] The share output that are losses.
  #
  def loss_output_conversion
    if loss = output(:loss)
      loss.conversion
    else
      0.0
    end
  end


  # --------- API -------------------------------------------------------------

  def query( method_name = nil)
     if method_name.nil?
      converter_api
    else
      converter_api.send(method_name)
    end
  end
  alias_method :proxy, :query

  # Sort of a hack, because we sometimes call converter on a
  # converter_api object, to get the converter.
  # Should actually be removed and made proper when we have time.
  #
  def converter
    self
  end

  # needed for url_for
  def to_param
    key.to_s
  end

  # --------- Debug -----------------------------------------------------------

  def name
    @key
  end

  def to_s
    @key
  end

  def inspect
    "<Converter #{@key}>"
  end

  def to_image(depth = 1, svg_path = nil)
    converters = [self]
    rgt_converters = [self]
    lft_converters = [self]
    1.upto(depth) do |i|
      lft_converters = lft_converters.map{|c| [c, c.lft_converters] }.uniq.flatten
      rgt_converters = rgt_converters.map{|c| [c, c.rgt_converters] }.uniq.flatten
    end
    converters = [lft_converters, rgt_converters].flatten
    g = GraphDiagram.new(converters, svg_path)
  end
end

end
