module Qernel
##
# TODO (interface so that):
# g = Qernel::Graph.new([Qernel::Converter], [Qernel::Carrier])
# g.links = [Qernel::Link]
# g.slot = [Qernel::Slot]
#
# g can now be cached
#
# g.dataset = Dataset.new
# g.optimize_calculation_order (needs dataset) (this should be cached as well)
# g.calculate
#
#
class Graph
  extend  ActiveModel::Naming
  include ActiveSupport::Callbacks
  include Instrumentable

  define_callbacks :calculate

  include Plugins::MeritOrder
  include Plugins::Fce

  # ---- DatasetAttributes ----------------------------------------------------

  include DatasetAttributes

  dataset_accessors :calculated,
                    :year,
                    :use_fce,
                    # graphs do not know the number of years, which is defined in 
                    # scenario.
                    :number_of_years 

  def dataset_key
    :graph
  end

  def graph
    self
  end

  attr_reader :converters
  attr_writer :goals
  
  attr_accessor :dataset,
                :finished_converters,
                :area,
                :graph_id


  # def initialize(converters, carriers, groups)
  def initialize(converters = [])
    self.converters = converters
    self.area = Qernel::Area.new(self)
  end

  def connect_qernel
    converters.each do |converter|
      converter.graph = self
      converter.slots.each {|s| s.graph = self}
    end
    links.each {|obj| obj.graph = self }
    # carriers.each {|obj| obj.graph = self }
  end

  def converters=(converters)
    @converters = converters
    @converters.each{|converter| converter.graph = self }

    self.reset_memoized_methods

    @converters
  end

  def dataset=(dataset)
    @dataset = dataset
    refresh_dataset_objects if @dataset
    # lookup hash for #converter( ) method uses :excel_id from dataset
    # so we have to reset the lookup
    reset_converter_lookup_and_memoize if @dataset
  end

  # Removes dataset from graph and all its objects.
  #
  def reset_dataset!
    @dataset = nil
    reset_dataset_objects
  end

  def each_dataset_object_item(method_name)
    self.send(method_name)
    self.converters.each do |c|
      c.query.send(method_name)
      c.send(method_name)
      c.input_links.each(&method_name)
      c.inputs.each(&method_name)
      c.outputs.each(&method_name)
    end
    self.area.send(method_name)
    self.carriers.each(&method_name)
  end

  def reset_dataset_objects
    each_dataset_object_item(:reset_object_dataset)
    reset_goals
  end

  def refresh_dataset_objects
    # See Qernel::Dataset#assign_object_dataset to understand what's going on:    
    each_dataset_object_item(:assign_object_dataset)
    reset_goals
  end

  def calculated?
    self[:calculated] == true
  end

  def enable_merit_order?
    query(:enable_merit_order?)
  end

  def time_curves
    dataset.time_curves
  end

  def present?
    raise "Qernel::Graph#present? #year not defined" if year.nil?
    year == START_YEAR
  end

  ##
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
  # TODO refactor
  def calculate(options = {})
    run_callbacks :calculate do

      if calculated?
        ActiveSupport::Notifications.instrument("gql.debug", "Graph already calculated")
        return
      end

      # FIFO stack of all the converters. Converters are removed from the stack after calculation.
      converter_stack = converters.clone
      self.finished_converters = []

      # delete_at is much faster as delete, that's why use #index rather than #detect
      while index = converter_stack.index(&:ready?)
        converter = converter_stack[index]
        converter.calculate
        self.finished_converters << converter_stack.delete_at(index)
      end

      self.finished_converters.map(&:input_links).flatten.each(&:update_share)

      unless converter_stack.empty?
        ActiveSupport::Notifications.instrument("gql.debug",
          "Following converters have not finished: #{converter_stack.map(&:full_key).join(', ')}")
      end
    end
    self[:calculated] = true
  end

  def links
    @links ||= converters.map(&:input_links).flatten.uniq
  end

  def groups
    @groups ||= converters.map(&:groups).flatten.uniq
  end

  def primary_energy_carriers
    @primary_energy_carriers ||= group_converters(:primary_energy_demand).map{|c| c.output_carriers}.flatten.uniq
  end

  def carrier(key)
    carriers.detect{|c| c.key == key.to_sym or c.id.to_s == key.to_s}
  end

  def carriers
    # The list of carriers is retrieved by looking at all slots, not just
    # links, so that "orphan" carriers used only for initial input (e.g.
    # imported_steam_hot_water) get included.
    @carriers ||=
      converters.each_with_object(Set.new) do |converter, carriers|
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

  ##
  # Return all converters in the given sector.
  #
  # @param sector_key [String,Symbol] sector identifier
  # @return [Array<Converter>]
  #
  def use_converters(key)
    use_key_sym = key.to_sym
    self.converters.select{|c| c.use_key == use_key_sym }
  end

  ##
  # Return all converters in the given sector.
  #
  # @param sector_key [String,Symbol] sector identifier
  # @return [Array<Converter>]
  #
  def sector_converters(sector_key)
    sector_key_sym = sector_key.to_sym
    self.converters.select{|c| c.sector_key == sector_key_sym }
  end

  ##
  # Return all converters in the given sector.
  #
  # @param sector_key [String,Symbol] sector identifier
  # @return [Array<Converter>]
  #
  def group_converters(group_key)
    group_key_sym = group_key.to_sym

    @group_converters_cache[group_key_sym] ||= 
      self.converters.select{|c| c.groups.include?(group_key_sym) }
  end

  ##
  # Return the converter with given id or key. See {Qernel::Converter::KEYS_FOR_LOOKUP} for used keys
  #
  # @param id [Integer,String] lookup key for converter
  # @return [Converter]
  #
  def converter(id)
    id = id.to_sym if id.is_a?(String)
    @converters_hash[id]
  end


  def to_image
    g = GraphDiagram.new(self.converters)
    g.generate('graph')
  end


  ##
  # Overwrite inspect to not inspect. Otherwise it crashes due to interlinkage of converters.
  def inspect
    "<Qernel::Graph>"
  end

  # optimizes calculation speed of graph by rearranging order of converters array
  #
  # @todo Calculate graph, and order converters array according to finished_converters
  def optimize_calculation_order
    copy = Marshal.load(Marshal.dump(self))
    copy.calculate
    copy.finished_converters.reverse.each_with_index do |converter, index|
      if old = converters.detect{|c| c.id == converter.id}
        converters.delete(old)
        converters.unshift(old)
      end
    end
  end

  def reset_memoized_methods
    reset_group_converters_and_memoize
    reset_converter_lookup_and_memoize

    @carriers = nil
    @links = nil
    @groups = nil
    @primary_energy_carriers = nil
  end
  
  # Goal-related methods
  #
  
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
  
private

  def reset_group_converters_and_memoize
    @group_converters_cache = {}
    groups.uniq.each {|key| group_converters(key)}
  end

  def reset_converter_lookup_and_memoize
    @converters_hash = {}
    self.converters.each do |converter|
      Qernel::Converter::KEYS_FOR_LOOKUP.each do |method_for_key|
        @converters_hash[converter.send(method_for_key)] = converter
      end
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
    def connect(lft, rgt, carrier, link_type = :share)
      lft = converter(lft) if lft.is_a?(Symbol)
      rgt = converter(rgt) if rgt.is_a?(Symbol)

      unless lft.input(carrier)
        lft.add_slot(Slot.new(lft.id+100, lft, carrier, :input).with({:conversion => 1.0}))
      end
      unless rgt.output(carrier)
        rgt.add_slot(Slot.new(rgt.id+200, rgt, carrier, :output).with({:conversion => 1.0}))
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
