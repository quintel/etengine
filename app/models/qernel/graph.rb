module Qernel
# Graph connects and datasets, nodes, links, carriers. It controls the
# main calculation logic and gives allows for plugins to hook into the
# calculation.
#
#     g = Qernel::Graph.new([Qernel::Node], [Qernel::Carrier])
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

  PLUGINS = [ Plugins::DisableSectors,
              Plugins::SimpleMeritOrder,
              Plugins::Causality,
              Plugins::FCE,
              Plugins::MaxDemandRecursive,
              Plugins::ResettableSlots ]

  # ---- DatasetAttributes ----------------------------------------------------

  include DatasetAttributes

  dataset_accessors :calculated,
                    :year,
                    :use_fce,
                    :flexibility_order,
                    :heat_network_order,
                    # graphs do not know the number of years, that is defined
                    # in scenario and assigned in a 2nd step by the gql.
                    :number_of_years

  def dataset_key
    :graph
  end

  def graph
    self
  end

  attr_reader :nodes, :logger
  attr_writer :goals, :cache_dataset_fetch

  attr_accessor :dataset,
                :finished_nodes,
                :area

  delegate :time_curves, to: :dataset
  delegate :insulation_costs, :weather_properties, to: :area

  # def initialize(nodes, carriers, groups)
  def initialize(nodes = [])
    @logger = ::Qernel::Logger.new
    @area   = Qernel::Area.new(self)

    @nodes_by_group = {}
    @links_by_group = {}

    self.nodes = nodes

    self.cache_dataset_fetch = true
  end

  # Public: Returns the plugin identified by the given +name+ which was used
  # during calculation of the graph. Returns nil if no such plugin exists, or if
  # it wasn't used in this scenario.
  def plugin(name)
    # Temporary backwards compatibility.
    if name.to_sym == :merit && lifecycle.plugins[:time_resolve]
      return lifecycle.plugins[:time_resolve].merit
    end

    lifecycle.plugins[name.to_sym]
  end

  # Assigns self to the graph variables of every qernel objects. The qernel
  # objects access dataset currently through graph. This could be optimized by
  # assigning the dataset object instead, but some objects need(ed?) access to
  # graph anyway, so that was a convenient.
  #
  def assign_graph_to_qernel_objects
    nodes.each do |node|
      node.graph = self
      node.slots.each { |s| s.graph = self }
    end
    links.each    { |l| l.graph = self }
    carriers.each { |c| c.graph = self }
  end

  # Assigning new nodes will also invalidate memoized lookup tables that
  # are related to nodes.
  #
  def nodes=(nodes)
    @nodes = nodes
    reset_memoized_methods
    @nodes
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

  # Runs the given block, ensuring that the original lifecycle used on the graph
  # is kept at the end of the block. This is useful when running code which
  # might change the lifecycle, such as during graph calculation.
  def retaining_lifecycle
    lc = lifecycle
    yield
    dataset_set(:lifecycle, lc)

    self
  end

  # Calls method_name on every qernel object including graph itself.
  # => caution: stacklevel too deep
  #
  def call_on_each_qernel_object(method_name)
    self.send(method_name)
    area.send(method_name)
    carriers.each(&method_name)

    nodes.each do |c|
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

  def present?
    year == @area.analysis_year
  end

  def future?
    ! present?
  end

  def period
    @period ||= present? ? :present : :future
  end

  def update_link_shares
    @finished_nodes.map(&:input_links).flatten.each(&:update_share)
  end

  def links
    @links ||= nodes.map(&:input_links).flatten.uniq
  end

  def groups
    @groups ||= nodes.map(&:groups).flatten.uniq
  end

  def carrier(key)
    carriers.detect{ |c| c.key == key.to_sym or c.id.to_s == key.to_s }
  end

  def carriers
    # The list of carriers is retrieved by looking at all slots, not just
    # links, so that "orphan" carriers used only for initial input also
    # get included.
    @carriers ||= nodes.each_with_object(Set.new) do |node, carriers|
      node.slots.each { |slot| carriers.add slot.carrier }
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

  # Return all nodes in the given sector.
  #
  # @param sector_key [String,Symbol] sector identifier
  # @return [Array<Node>]
  #
  def use_nodes(key)
    use_key_sym = key.to_sym
    self.nodes.select{|c| c.use_key == use_key_sym }
  end

  def sectors
    nodes.map(&:sector_key).uniq.compact
  end

  # Return all nodes in the given sector.
  #
  # @param sector_key [String,Symbol] sector identifier
  # @return [Array<Node>]
  #
  def sector_nodes(sector_key)
    key = sector_key.to_sym
    nodes.select{|c| c.sector_key == key }
  end

  # Return all nodes in the given sector.
  #
  # @param sector_key [String,Symbol] sector identifier
  # @return [Array<Node>]
  #
  def group_nodes(group_key)
    key = group_key.to_sym
    @nodes_by_group[key] ||= nodes.select{|c| c.groups.include?(key) }
  end

  # Return all links in the given group.
  #
  # @param group_key [String,Symbol] group identifier
  # @return [Array<Node>]
  #
  def group_links(group_key)
    key = group_key.to_sym
    @links_by_group[key] ||= links.select{ |link| link.groups.include?(key) }
  end

  # Return the node with given key.
  #
  # @param id [Integer,String] lookup key for node
  # @return [Node]
  #
  def node(id)
    id = id.to_sym if id.is_a?(String)
    @nodes_hash[id]
  end

  # Graphviz
  def to_image
    g = GraphDiagram.new(self.nodes)
    g.generate('graph')
  end


  # Overwrite inspect to not inspect. Otherwise it crashes due to interlinkage of nodes.
  def inspect
    "<Qernel::Graph>"
  end

  # --- Calculation ----------------------------------------------------------

  # Has graph finished calculating.
  #
  def calculated?
    calculated == true
  end

  def lifecycle
    # Bypass "fetch", which will not actually set the lifecycle onto the dataset
    # during a "without_dataset_caching" block.
    dataset_get(:lifecycle) || dataset_set(:lifecycle, Lifecycle.new(self))
  end

  # Calculates the Graph.
  #
  # = Algorithm
  #
  # 1. Take first node that is "ready for calculation" (see {Qernel::Node#ready?}) from the node stack
  # 2. Calculate the node (see: {Qernel::Node#calculate})
  # 3. Remove node from stack and move it to {#finished_nodes}
  # 5. => (continue at 1. until stack is empty)
  # 6. recalculate link shares of output_links (see: {Qernel::Link#update_share})
  #
  def calculate(options = {})
    lifecycle.calculate
  end

  # A calculation_loop is one cycle of calculating nodes until there is
  # no node left to calculate (no nodes is #ready? anymore). This
  # can mean that the calculation is finished or that we need to run a
  # "plugin" (e.g. merit order). The plugin most likely will update some
  # node demands, what "unlocks" more nodes and the calculation can
  # continue.
  #
  def calculation_loop
    # FIFO stack of all the nodes. Nodes are removed from the stack after calculation.
    @node_stack = nodes.clone
    @finished_nodes = []

    while index = @node_stack.index(&:ready?)
      node = @node_stack[index]
      node.calculate
      @finished_nodes << @node_stack.delete_at(index)
    end
    update_link_shares
  end


  # optimizes calculation speed of graph by rearranging the order of the nodes array.
  #
  # Basic idea is to run a brute-force calculation, after the optimal way of
  # traversing through the graph can be found in finished_nodes.
  #
  # @example
  #      # Load topology from etsource, random ordering of nodes:
  #      # nodes: [node_1, node_2, node_3]
  #      node_1.ready?     # => false
  #      node_2.ready?     # => false
  #      node_3.ready?     # => true
  #      node_3.calculate  # => finished_nodes: [node_3]
  #      node_1.ready?     # => false
  #      node_2.ready?     # => true    | calculating node_3 makes _2 calculateable/ready
  #      node_2.calculate  # => finished_nodes: [node_3, node_2]
  #      node_1.ready?     # => true    | calculating node_2 makes _1 calculateable/ready
  #      node_1.calculate  # => finished_nodes: [node_3, node_2, node_1]
  #      # reorder the nodes array according to finished_nodes
  #      # nodes: [node_3, node_2, node_1]
  #      # From now on nodes are correctly ordered and we save us lots of expensive ready? checks:
  #      node_3.ready?     # => true
  #      node_3.calculate
  #      node_2.ready?     # => true
  #      node_2.calculate
  #      node_1.ready?     # => true
  #      node_1.calculate
  #
  #
  def optimize_calculation_order
    copy = DeepClone.clone self #Marshal.load(Marshal.dump(self))
    copy.calculate
    copy.finished_nodes.reverse.each_with_index do |node, index|
      if old = nodes.detect{|c| c.id == node.id}
        nodes.delete(old)
        nodes.unshift(old)
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
    @nodes_by_group = {}

    regenerate_node_lookup
  end

  # Regenerate a lookup hash for nodes, used by #node( key_or_excel_id )
  #
  def regenerate_node_lookup
    @nodes_hash = {}

    nodes.each do |node|
      @nodes_hash[node.key] = node
    end
  end

  def graph_query
    @graph_query ||= GraphApi.new(self)
  end

  def initializer_inputs
    decorated_inputs.sort_by { |input, _| [-input.priority, input.key] }
  end

  def decorated_inputs
    (area.init || {}).map do |input_key, input_value|
      [InitializerInput.fetch(input_key), input_value]
    end
  end

  def cache_dataset_fetch?
    @cache_dataset_fetch
  end

  # Public: Disables dataset caching for the duration of the block.
  #
  # During execution, calls to 'fetch' for values which are not already present
  # on the dataset will trigger the resulting values to be cached.
  #
  # Returns the value of the block.
  def without_dataset_caching
    previous_setting = @cache_dataset_fetch
    @cache_dataset_fetch = false

    yield
  ensure
    @cache_dataset_fetch = previous_setting
  end

  # ====== Methods only used for Testing =============================

  if Rails.env.test? || Rails.env.development?
    # create slot if necessary.
    # return link
    def connect(lft, rgt, carrier, link_type = :share, reversed = false,
                left_slot_type = nil, right_slot_type = nil)

      lft = node(lft) if lft.is_a?(Symbol)
      rgt = node(rgt) if rgt.is_a?(Symbol)

      unless lft.input(carrier)
        lft.add_slot(Slot.factory(left_slot_type, lft.id+100, lft, carrier, :input).with({:conversion => 1.0}))
      end
      unless rgt.output(carrier)
        rgt.add_slot(Slot.factory(right_slot_type, rgt.id+200, rgt, carrier, :output).with({:conversion => 1.0}))
      end
      Link.new([lft.id, rgt.id].join('').to_i, lft, rgt, carrier, link_type, reversed)
    end

    def with_nodes(key_dataset_hsh)
      self.nodes = key_dataset_hsh.map do |key, dataset|
        Node.new(id: self.nodes.length+1, key: key).with(dataset)
      end
    end
  end
end
end
