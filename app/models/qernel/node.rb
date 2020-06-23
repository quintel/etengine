module Qernel

##
# == demand and preset_demand
#
# preset_demand differs from demand, in that it's not changed by
# the calculation. This way we can access if a node is assigned
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
# We do this in NodeData < ActiveRecord::Base
#
# Also note that some update statements modify preset_demand, rather then
# demand.
#
# = Naming of child/parent nodes and their edges
#
# <tt>[Demander <b>D</b>]  <---Edge <b>L</b> --- [Supplyer <b>S</b>]</tt>
#
# * Energy flows from S to D.
# * D demands energy from S
#
# * D is parent of S
# * D has a input_edge(/downstream/supplying) Edge L.
#
# * S is child of D
# * S has an output_edge(upstream/demanding_edge) edge L to D
#
# * If edge L is share, flexible or constant, D assigns a value to L
# * If edge L is dependent, S assigns a value to L.
#
#
# * <tt>c.input_edges = c.input_edges</tt>
# * <tt>c.output_edges = c.output_edges</tt>
#
#
# Node is ready? to fill own demand:
#
# Node is ready to assign depending_demand_edge_value if:
# - <tt>output_edges.reject(&:depending?).all?(&:value)</tt>
# Special Case: output_edges.reject(&:depending?).empty? and input_edges.select(&:depending?).present?
#
#
#
# depending_demand_edge_value = SUM(fixed & flexible output edges) - SUM(dependent_input_edges)
#
# If demand is set, assign supplying demanding edge
#
class Node
  extend ActiveModel::Naming

  include Qernel::RecursiveFactor::Base
  include Qernel::RecursiveFactor::PrimaryDemand
  include Qernel::RecursiveFactor::BioDemand
  include Qernel::RecursiveFactor::DependentSupply
  include Qernel::RecursiveFactor::FinalDemand
  include Qernel::RecursiveFactor::PrimaryCo2
  include Qernel::RecursiveFactor::WeightedCarrier
  include Qernel::RecursiveFactor::Sustainable

  include Qernel::RecursiveFactor::MaxDemand

  include DatasetAttributes

  attr_reader  :id,
               :output_edges,
               :input_edges,
               :groups,
               :sector_key,
               :use_key,
               :presentation_group

  attr_accessor :node_api, :key, :graph

  # The API type used by the node.
  #
  # @return [Symbol]
  #   Returns which API type is used when performing calculations. Either
  #   :default or :demand_driven
  #
  attr_reader :type

  alias_method :lft_edges, :output_edges
  alias_method :rgt_edges, :input_edges

  dataset_accessors %i[
    demand
    excel_id
    fever
    heat_network
    hydrogen
    merit_order
    network_gas
    preset_demand
    storage
    waste_outputs
  ]

  # --------- Micro-optimizing ------------------------------------------------
  #
  # This is really just for micro-optimizing code
  # as attr_readers are faster then normal method calls.
  attr_reader :sector_environment
  alias sector_environment? sector_environment

  attr_reader :primary_energy_demand, :useful_demand, :final_demand_group, :non_energetic_use, :energy_import_export, :bio_resources_demand
  alias primary_energy_demand? primary_energy_demand
  alias useful_demand? useful_demand
  alias final_demand_group? final_demand_group
  alias non_energetic_use? non_energetic_use
  alias energy_import_export? energy_import_export
  alias bio_resources_demand? bio_resources_demand

  # --------- Initializing ----------------------------------------------------

  # @example Initialize a new node
  #   Qernel::Node.new(key: 'foo')
  #
  def initialize(opts)
    if !(opts.include?(:id) || opts.include?(:key))
      raise ArgumentError.new("Either :id or :key has to be passed to Qernel::Node.new")
    end

    @id         = opts[:id] || Hashpipe.hash(opts[:key])
    @key        = opts[:key]
    @groups     = opts[:groups] || []
    @use_key    = opts[:use_id]
    @sector_key = opts[:sector_id]
    @presentation_group = opts[:presentation_group]

    @output_edges, @input_edges = [], []
    @output_hash, @input_hash = {}, {}

    memoize_for_cache

    self.node_api = Qernel::NodeApi.for_node(self)

    @calculation_state = :initialized
  end

  # return the excel id as a symbol for the graph#node_lookup_hash
  # return the key if no excel_id defined or dataset not initialised yet.
  #
  def excel_id_to_sym
    if dataset_attributes
      (excel_id || key).to_s.to_sym
    else
      key
    end
  end

  # Public: Does this node represent energy flow from outside the modelled region?
  #
  # Returns true or false.
  def abroad?
    # Double-negate as abroad may be nil.
    !!dataset_get(:abroad)
  end

  # Public: When true, this node should be ignored in recursive factor
  # calculations (always returning zero), and will prevent further recusion.
  #
  # Returns true or false.
  def recursive_factor_ignore?
    @recursive_factor_ignore
  end

  protected

  # Memoize here, so it doesn't have to at runtime
  #
  def memoize_for_cache
    @sector_environment    = sector_key === :environment

    @primary_energy_demand = @groups.include? :primary_energy_demand
    @useful_demand         = @groups.include? :useful_demand
    @final_demand_group    = @groups.include? :final_demand_group
    @non_energetic_use     = @groups.include? :non_energetic_use
    @energy_import_export  = @groups.include? :energy_import_export
    @bio_resources_demand  = @groups.include? :bio_resources_demand

    @recursive_factor_ignore = @groups.include? :recursive_factor_ignore

    self.dataset_key # memoize dataset_key
  end

public
  def self.dataset_group; :graph; end

  # Set the graph so that we can access other  parts.
  #
  def graph=(graph)
    @graph = graph
    self.node_api.graph = @graph
    self.node_api.area = @graph.area
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

  # @param edge [Edge]
  #
  def add_output_edge(edge)
    @output_edges << edge
  end

  # @param edge [Edge]
  #
  def add_input_edge(edge)
    @input_edges << edge
  end

  # @param slot [Qernel::Slot]
  # @return [Qernel::Slot]
  #
  def add_slot(slot)
    slot.node = self

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
  # the same node, and helps to only have positive energy flows.
  def has_loop?
    # if lft_nodes and children have one node in common it is a loop
    (lft_nodes & rgt_nodes).length > 0
  end

  # @return [Array<Node>] Nodes to the right
  #
  def rgt_nodes
    @rgt_nodes ||= input_edges.map(&:rgt_node)
  end

  # @return [Array<Node>] Nodes to the left
  #
  def lft_nodes
    @lft_nodes ||= output_edges.map(&:lft_node)
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
  # node.input(:electricity)
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
  # node.output(:electricity)
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

  # Can the node demand be calculated?
  #
  # @return [true,false]
  #
  def ready?
    slots.all?(&:ready?)
  end

  # Calculates the demand of the node and of the edges that depend on this demand.
  #
  # == Algorithm
  #
  # 1. (unless preset_demand is set) Sums demand of output_edges (without dependent edges) edges.
  #
  # @pre node must be #ready?
  #
  def calculate
    @calculation_state = :calculate

    # Constant edges are treated differently.
    # They can overwrite the preset_demand of this node
    output_edges.select(&:constant?).each(&:calculate)

    # this is an attempt to solve this issue
    # https://github.com/dennisschoenmakers/etengine/issues/258
    input_edges.select(&:constant?).each(&:calculate) if output_edges.any?(&:inversed_flexible?)

    # If the demand is already set (is not nil), do not overwrite it.
    if self.demand.nil?
      self.demand ||= update_demand
    end # Demand is set
    @calculation_state = :calculating_after_update_demand

    # Now calculate the slots of this node
    slots.each(&:calculate)

    # inversed_flexible fills up the difference of the calculated input/output slot.
    output_edges.select(&:inversed_flexible?).each(&:calculate)
  end

protected

  # The highest internal_value of in/output slots is the demand of
  # this node. If there are slots with different internal_values
  # they have to update their passive edges, (this happens in #calculate).
  #
  # @pre node must be #ready?
  # @pre has to be used from within #calculate, as slots have to be adjusted
  #
  # @return [Float] The demand of this node
  #
  def update_demand
    if output_edges.any?(&:inversed_flexible?) or output_edges.any?(&:reversed?)
      @calculation_state = :update_demand_if_inversed_flexible_or_reversed
      slots.map(&:internal_value).compact.max
    elsif output_edges.empty?
      @calculation_state = :update_demand_if_no_output_edges
      # 2010-06-23: If there is no output edges we take the highest value from input.
      # otherwise left dead end nodes don't get values
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
  def input_carriers; input_edges.map(&:carrier).compact; end

  # @return [Array<Carrier>] Carriers of output
  #
  def output_carriers; output_edges.map(&:carrier).compact; end


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
      node_api
    else
      node_api.send(method_name)
    end
  end
  alias_method :proxy, :query

  # Sort of a hack, because we sometimes call node on a
  # node_api object, to get the node.
  # Should actually be removed and made proper when we have time.
  #
  def node
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
    "#<Node #{@key}>"
  end

  def to_image(depth = 1, svg_path = nil)
    nodes = [self]
    rgt_nodes = [self]
    lft_nodes = [self]
    1.upto(depth) do |i|
      lft_nodes = lft_nodes.map{|c| [c, c.lft_nodes] }.uniq.flatten
      rgt_nodes = rgt_nodes.map{|c| [c, c.rgt_nodes] }.uniq.flatten
    end
    nodes = [lft_nodes, rgt_nodes].flatten
    g = GraphDiagram.new(nodes, svg_path)
  end
end

end
