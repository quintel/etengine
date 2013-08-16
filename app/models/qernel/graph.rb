module Qernel
# Graph connects and datasets, converters, links, carriers. It controls the
# main calculation logic and gives allows for plugins to hook into the
# calculation.
#
#     g = Qernel::Graph.new([Qernel::Converter], [Qernel::Carrier])
#     g.links = [Qernel::Link]
#     g.slot  = [Qernel::Slot]
#     # g can now be cached
#     g.dataset = Dataset.new
#     g.optimize_calculation_order (needs dataset) (this should be cached as well)
#     g.calculate
#
#
class Graph
  extend  ActiveModel::Naming
  include ActiveSupport::Callbacks
  include Instrumentable

  define_callbacks :calculate,
                   :calculate_initial_loop


  # Concerns (Required Plugin)
  include Plugins::MeritOrder
  include Plugins::Fce
  include Plugins::MaxDemandRecursive
  include Plugins::ResettableSlots

  # ---- DatasetAttributes ----------------------------------------------------

  include DatasetAttributes

  dataset_accessors :calculated,
                    :year,
                    :use_fce,
                    :use_merit_order_demands,
                    # graphs do not know the number of years, that is defined
                    # in scenario and assigned in a 2nd step by the gql.
                    :number_of_years

  def dataset_key
    :graph
  end

  def graph
    self
  end

  attr_reader :converters, :logger
  attr_writer :goals

  attr_accessor :dataset,
                :finished_converters,
                :area


  # def initialize(converters, carriers, groups)
  def initialize(converters = [])
    @logger = ::Qernel::Logger.new
    @area   = Qernel::Area.new(self)
    @converters_by_group = {}

    self.converters = converters
  end

  # Assigns self to the graph variables of every qernel objects. The qernel
  # objects access dataset currently through graph. This could be optimized by
  # assigning the dataset object instead, but some objects need(ed?) access to
  # graph anyway, so that was a convenient.
  #
  def assign_graph_to_qernel_objects
    converters.each do |converter|
      converter.graph = self
      converter.slots.each { |s| s.graph = self }
    end
    links.each    { |l| l.graph = self }
    carriers.each { |c| c.graph = self }
  end

  # Assigning new converters will also invalidate memoized lookup tables that
  # are related to converters.
  #
  def converters=(converters)
    @converters = converters
    reset_memoized_methods
    @converters
  end

  # Assigning a new dataset will also attach it to all qernel objects.
  #
  # graph.dataset = nil will detach the dataset_attributes from qernel objects.
  #
  def dataset=(dataset)
    @dataset = dataset
    if @dataset.nil?
      remove_dataset_attributes
    else
      refresh_dataset_attributes
    end
  end

  # Removes dataset from graph and all its objects.
  # More verbose version of:
  #
  #     graph.dataset = nil
  #
  def detach_dataset!
    self.dataset = nil
  end

  # Calls method_name on every qernel object including graph itself.
  # => caution: stacklevel too deep
  #
  def call_on_each_qernel_object(method_name)
    self.send(method_name)
    area.send(method_name)
    carriers.each(&method_name)

    converters.each do |c|
      c.query.send(method_name)
      c.send(method_name)
      c.input_links.each(&method_name)
      c.inputs.each(&method_name)
      c.outputs.each(&method_name)
    end
  end

  # Removes dataset object from qernel objects
  #
  def remove_dataset_attributes
    call_on_each_qernel_object(:reset_dataset_attributes)
    reset_goals
  end

  # Reassigns the dataset attributes to qernel objects.
  # Use this when you assign the graph a new dataset.
  #
  def refresh_dataset_attributes
    # See Qernel::Dataset#assign_dataset_attributes to understand what's going on:
    call_on_each_qernel_object(:assign_dataset_attributes)
    reset_goals
  end

  def time_curves
    dataset.time_curves
  end

  def present?
    raise "Qernel::Graph#present? #year not defined" if year.nil?
    year == START_YEAR
  end

  def future?
    year != START_YEAR
  end

  def update_link_shares
    @finished_converters.map(&:input_links).flatten.each(&:update_share)
  end

  def links
    @links ||= converters.map(&:input_links).flatten.uniq
  end

  def groups
    @groups ||= converters.map(&:groups).flatten.uniq
  end

  def carrier(key)
    carriers.detect{ |c| c.key == key.to_sym or c.id.to_s == key.to_s }
  end

  def carriers
    # The list of carriers is retrieved by looking at all slots, not just
    # links, so that "orphan" carriers used only for initial input (e.g.
    # imported_steam_hot_water) get included.
    @carriers ||= converters.each_with_object(Set.new) do |converter, carriers|
      converter.slots.each { |slot| carriers.add slot.carrier }
    end.freeze
  end

  # used by gql
  def query(method_name = nil)
    if method_name.nil?
      graph_query
    else
      graph_query.send(method_name)
    end
  end

  # Return all converters in the given sector.
  #
  # @param sector_key [String,Symbol] sector identifier
  # @return [Array<Converter>]
  #
  def use_converters(key)
    use_key_sym = key.to_sym
    self.converters.select{|c| c.use_key == use_key_sym }
  end

  def sectors
    converters.map(&:sector_key).uniq.compact
  end

  # Return all converters in the given sector.
  #
  # @param sector_key [String,Symbol] sector identifier
  # @return [Array<Converter>]
  #
  def sector_converters(sector_key)
    key = sector_key.to_sym
    converters.select{|c| c.sector_key == key }
  end

  # Return all converters in the given sector.
  #
  # @param sector_key [String,Symbol] sector identifier
  # @return [Array<Converter>]
  #
  def group_converters(group_key)
    key = group_key.to_sym
    @converters_by_group[key] ||= converters.select{|c| c.groups.include?(key) }
  end

  # Return the converter with given key.
  #
  # @param id [Integer,String] lookup key for converter
  # @return [Converter]
  #
  def converter(id)
    id = id.to_sym if id.is_a?(String)
    @converters_hash[id]
  end

  # Graphviz
  def to_image
    g = GraphDiagram.new(self.converters)
    g.generate('graph')
  end


  # Overwrite inspect to not inspect. Otherwise it crashes due to interlinkage of converters.
  def inspect
    "<Qernel::Graph>"
  end

  # --- Calculation ----------------------------------------------------------

  # Has graph finished calculating.
  #
  def calculated?
    calculated == true
  end

  # Calculates the Graph.
  #
  # = Algorithm
  #
  # 1. Take first converter that is "ready for calculation" (see {Qernel::Converter#ready?}) from the converter stack
  # 2. Calculate the converter (see: {Qernel::Converter#calculate})
  # 3. Remove converter from stack and move it to {#finished_converters}
  # 5. => (continue at 1. until stack is empty)
  # 6. recalculate link shares of output_links (see: {Qernel::Link#update_share})
  #
  def calculate(options = {})
    run_callbacks :calculate do
      return if calculated?

      instrument("gql.performance.calculate") do

        if use_merit_order_demands? && future?
          dataset_copy = DeepClone.clone @dataset #Marshal.load(Marshal.dump(@dataset))
        end

        calculation_loop # the initial loop

        if use_merit_order_demands? && future?
          mo = Plugins::MeritOrder::MeritOrderInjector.new(self)
          mo.run
          goals_copy = goals
          # detaching the dataset clears the goals - which is the correct
          # behaviour, but with the double calculation loop required by MO
          # they should be restored
          detach_dataset!
          self.dataset = dataset_copy
          self.goals   = goals_copy
          mo.inject_values
          calculation_loop
        end
      end
    end
    calculated = true
  end

  # A calculation_loop is one cycle of calculating converters until there is
  # no converter left to calculate (no converters is #ready? anymore). This
  # can mean that the calculation is finished or that we need to run a
  # "plugin" (e.g. merit order). The plugin most likely will update some
  # converter demands, what "unlocks" more converters and the calculation can
  # continue.
  #
  def calculation_loop
    # FIFO stack of all the converters. Converters are removed from the stack after calculation.
    @converter_stack = converters.clone
    @finished_converters = []

    while index = @converter_stack.index(&:ready?)
      converter = @converter_stack[index]
      converter.calculate
      @finished_converters << @converter_stack.delete_at(index)
    end
    update_link_shares
  end


  # optimizes calculation speed of graph by rearranging the order of the converters array.
  #
  # Basic idea is to run a brute-force calculation, after the optimal way of
  # traversing through the graph can be found in finished_converters.
  #
  # @example
  #      # Load topology from etsource, random ordering of converters:
  #      # converters: [converter_1, converter_2, converter_3]
  #      converter_1.ready?     # => false
  #      converter_2.ready?     # => false
  #      converter_3.ready?     # => true
  #      converter_3.calculate  # => finished_converters: [converter_3]
  #      converter_1.ready?     # => false
  #      converter_2.ready?     # => true    | calculating converter_3 makes _2 calculateable/ready
  #      converter_2.calculate  # => finished_converters: [converter_3, converter_2]
  #      converter_1.ready?     # => true    | calculating converter_2 makes _1 calculateable/ready
  #      converter_1.calculate  # => finished_converters: [converter_3, converter_2, converter_1]
  #      # reorder the converters array according to finished_converters
  #      # converters: [converter_3, converter_2, converter_1]
  #      # From now on converters are correctly ordered and we save us lots of expensive ready? checks:
  #      converter_3.ready?     # => true
  #      converter_3.calculate
  #      converter_2.ready?     # => true
  #      converter_2.calculate
  #      converter_1.ready?     # => true
  #      converter_1.calculate
  #
  #
  def optimize_calculation_order
    copy = DeepClone.clone self #Marshal.load(Marshal.dump(self))
    copy.calculate
    copy.finished_converters.reverse.each_with_index do |converter, index|
      if old = converters.detect{|c| c.id == converter.id}
        converters.delete(old)
        converters.unshift(old)
      end
    end
  end

  # --- Goal-related methods --------------------------------------------------


  # Returns an array with all the defined goals. The value is not memoized because
  # goals can be added dynamically
  #
  def goals
    @goals ||= []
  end

  # Returns a goal by key
  #
  def goal(key)
    goals.find {|g| g.key == key}
  end

  # finds or create goal as needed
  #
  def find_or_create_goal(key)
    unless g = goal(key)
      g = Goal.new(key)
      goals << g
    end
    return g
  end

  def reset_goals
    @goals = []
  end

  def reset_memoized_methods
    @carriers = nil
    @links    = nil
    @groups   = nil
    @converters_by_group = {}

    regenerate_converter_lookup
  end

  # Regenerate a lookup hash for converters, used by #converter( key_or_excel_id )
  #
  def regenerate_converter_lookup
    @converters_hash = {}

    converters.each do |converter|
      @converters_hash[converter.key] = converter
    end
  end

  def graph_query
    @graph_query ||= GraphApi.new(self)
  end

public

  # ====== Methods only used for Testing =============================

  if Rails.env.test? || Rails.env.development?
    # create slot if necessary.
    # return link
    def connect(lft, rgt, carrier, link_type = :share,
                left_slot_type = nil, right_slot_type = nil)

      lft = converter(lft) if lft.is_a?(Symbol)
      rgt = converter(rgt) if rgt.is_a?(Symbol)

      unless lft.input(carrier)
        lft.add_slot(Slot.factory(left_slot_type, lft.id+100, lft, carrier, :input).with({:conversion => 1.0}))
      end
      unless rgt.output(carrier)
        rgt.add_slot(Slot.factory(right_slot_type, rgt.id+200, rgt, carrier, :output).with({:conversion => 1.0}))
      end
      Link.new([lft.id, rgt.id].join('').to_i, lft, rgt, carrier, link_type)
    end

    def with_converters(key_dataset_hsh)
      self.converters = key_dataset_hsh.map do |key, dataset|
        Converter.new(id: self.converters.length+1, key: key).with(dataset)
      end
    end
  end



end

end
