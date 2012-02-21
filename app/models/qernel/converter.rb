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
# === Description
# 
# The trouble is that municipalities can decide to build wind mills, but
# the national scenario can have a certain amount of wind mills as well. 
#
# E.g. Municipality of Amsterdam wants to build 200 windmills, but The 
# Netherlands also has 2.000 windmills. Total is 2.200 windmills, but they 
# can only adjust the 200. Furthermore, sometimes you want to adjust the 
# national scenario (you wanna change the 2.000), and sometimes you wanna 
# change the 200. So, in fact sometimes you wanna use two sliders for the 
# same converter, one that keeps track of the 'national' windmills, and 
# another that keeps track of the 'municipality' windmills.
#
#
#
#
#
# = Naming of child/parent converters and their links
#
# <tt>[Demander <b>D</b>]  <---Link <b>L</b> --- [Supplyer <b>S</b>]</tt>
#
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

  include Converter::PrimaryDemand
  # include Qernel::WouterDance::Base
  # include Qernel::WouterDance::PrimaryDemand
  # include Qernel::WouterDance::FinalDemand
  # include Qernel::WouterDance::PrimaryCo2
  # include Qernel::WouterDance::WeightedCarrier

  include DatasetAttributes
  include Topology::Converter

  # Following keys can be looked up by {Qernel::Graph#converter}.
  KEYS_FOR_LOOKUP = [
    :excel_id_to_sym,
    :full_key
  ]

  SECTORS = {
    1 => :households,
    2 => :industry,
    3 => :transport,
    4 => :agriculture,
    5 => :energy,
    6 => :other,
    7 => :environment,
    8 => :buildings,
    9 => :neighbor
  }

  USES = {
    1 => :energetic,
    2 => :non_energetic,
    3 => :undefined
  }

  attr_reader  :id, 
               :code, 
               :output_links, 
               :input_links, 
               :groups, 
               :full_key, 
               :sector_key, 
               :use_key, 
               :energy_balance_group

  attr_accessor :converter_api, :key, :graph

  dataset_accessors [:demand, :preset_demand, :excel_id]

  # --------- Micro-optimizing ------------------------------------------------
  #
  # This is really just for micro-optimizing code
  # as attr_readers are faster then normal method calls.
  attr_reader :environment_converter, :sector_environment
  alias environment? environment_converter
  alias sector_environment? sector_environment

  attr_reader :primary_energy_demand, :useful_demand, :final_demand_cbs, :non_energetic_use, :energy_import_export
  alias primary_energy_demand? primary_energy_demand
  alias useful_demand? useful_demand
  alias final_demand_cbs? final_demand_cbs
  alias non_energetic_use? non_energetic_use
  alias energy_import_export? energy_import_export

  # --------- Initializing ----------------------------------------------------

  def initialize(opts)
    if !(opts.include?(:id) || opts.include?(:code))
      raise ArgumentError.new("Either :id or :code has to be passed to Qernel::Converter.new") 
    end
    @id        = opts[:id] || Hashpipe.hash(opts[:code])
    @key       = opts[:key]
    @code      = opts[:code]
    @groups    = opts[:groups] || []
    @energy_balance_group = opts[:energy_balance_group]
    
    @output_links, @input_links = [], []
    @output_hash, @input_hash = {}, {}

    use_id    = opts[:use_id]
    sector_id = opts[:sector_id]
        
    @use_key = use_id.is_a?(Symbol) ? use_id : USES[use_id]
    @sector_key = sector_id.is_a?(Symbol) ? sector_id : SECTORS[sector_id]
    custom_use_key = (@use_key === :undefined || @use_key.nil?) ? nil : @use_key.to_s
    @full_key = [@key, @sector_key, custom_use_key].compact.join("_").to_sym

    memoize_for_cache
    self.converter_api = Qernel::ConverterApi.new(self)
  end

  def self.full_key(key,sector_id,use_id)
    use_key = USES[use_id]
    sector_key = SECTORS[sector_id]

    custom_use_key = (use_key === :undefined || use_key.nil?) ? nil : use_key.to_s
    [key, sector_key, custom_use_key].compact.join("_").to_sym
  end

  # return the excel id as a symbol for the graph#converter_lookup_hash
  # return the full_key if no excel_id defined or dataset not initialised yet.
  #
  def excel_id_to_sym
    if object_dataset
      (excel_id || full_key).to_s.to_sym
    else
      full_key
    end
  end

protected

  # Memoize here, so it doesn't have to at runtime
  #
  def memoize_for_cache
    @environment_converter = full_key === :environment_environment
    @sector_environment = sector_key === :environment

    @primary_energy_demand = @groups.include? :primary_energy_demand
    @useful_demand = @groups.include? :useful_demand
    @final_demand_cbs = @groups.include? :final_demand_cbs
    @non_energetic_use = @groups.include? :non_energetic_use
    @energy_import_export = @groups.include? :energy_import_export

    self.dataset_key # memoize dataset_key
  end

public

  # Set the graph so that we can access other  parts.
  #
  def graph=(graph) 
    @graph = graph
    self.converter_api.graph = @graph
    self.converter_api.area = @graph.area
    @graph
  end

  # See {Qernel::Converter} for difference of demand/preset_demand
  #
  def preset_demand=(val)
    dataset_set(:preset_demand, safe_to_f(val)) 
    update_initial_demand
  end

  def demand
    dataset_get(:demand) || update_initial_demand
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
    # if parents and children have one converter in common it is a loop
    (parents & children).length > 0
  end

  # @return [Array<Converter>] Converters to the right
  #
  def children
    @children ||= input_links.map(&:child)
  end

  # @return [Array<Converter>] Converters to the left
  #
  def parents
    @parents ||= output_links.map(&:parent)
  end


  # @return [Array<Slot>] all input slots
  #
  def inputs
    @inputs ||= input_hash.values
  end

  # @return [Array<Slot>] all output slots
  #
  def outputs
    @outputs ||= output_hash.values
  end

  # @return [Array<Slot>] input *and* output slots
  #
  def slots
    @_slots ||= [inputs, outputs].flatten
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

    # Now calculate the slots of this controller
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
      slots.map(&:internal_value).compact.sort_by(&:abs).last
    elsif output_links.empty?
      # 2010-06-23: If there is no output links we take the highest value from input.
      # otherwise left dead end converters don't get values
      inputs.map(&:internal_value).compact.sort_by(&:abs).last
    else
      # 2010-06-23: The normal case. Just take the highest value from outputs.
      # We did this to make the gas_extraction gas_import_export thing work
      outputs.map(&:internal_value).compact.sort_by(&:abs).last
    end
  end

  # Updates the {demand} with the sum of preset_demand
  # It is needed to call this method everytime
  # we update either preset_demand, because
  # both attributes can be updated through GQL, we have to make
  # sure to always sum both values. 
  #
  # @return [Float] demand 
  #
  def update_initial_demand
    preset = dataset_get(:preset_demand)

    if preset.nil?
      nil
    else
      total = 0.0
      total += preset if preset

      self.demand = total
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
    full_key.to_s
  end

  # --------- Debug -----------------------------------------------------------

  def name
    full_key
  end

  def to_s
    "#{name} #{[self.excel_id]} (hash: #{@id})" || 'untitled'
  end

  def inspect
    "<Qernel::Converter full_key: #{full_key}>"
  end

  def to_image(depth = 1, svg_path = nil)
    converters = [self]
    children = [self]
    parents = [self]
    1.upto(depth) do |i|
      parents = parents.map{|c| [c, c.parents] }.uniq.flatten
      children = children.map{|c| [c, c.children] }.uniq.flatten
    end
    converters = [parents, children].flatten
    g = GraphDiagram.new(converters, svg_path)
  end
end

end
