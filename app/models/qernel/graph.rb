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
  extend ActiveModel::Naming
  include DatasetAttributes

  attr_accessor :dataset,
                :converters,
                :finished_converters,
                :area,
                :region_code,
                :year,
                :graph_id

  # ---- DatasetAttributes ----------------------------------------

  def dataset_key
    :graph
  end

  # used for DatasetAttributes
  def graph
    self
  end



  # def initialize(converters, carriers, groups)
  def initialize(converters, optimize = true, dataset = nil, carriers = nil)
    # TODO @calculated should be in Dataset
    @calculated = false

    self.converters = converters

    @group_converters_cache = {}

    self.area = Qernel::Area.new(self)
    build_lookup_hash

    prepare_memoization
  end

  def reset_dataset_objects
    self.object_dataset_reset
    self.area.object_dataset_reset
    self.carriers.each(&:object_dataset_reset)
    self.converters.each do |c|
      c.object_dataset_reset
      c.input_links.each(&:object_dataset_reset)
      c.inputs.each(&:object_dataset_reset)
    end
  end

  def calculated?
    dataset_get(:calculated)
  end

  def time_curves
    dataset.time_curves
  end

  def present?
    raise "Qernel::Graph#present? #year not defined" if year.nil?
    year == Current.scenario.start_year
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
  # 6. recalculate link shares of output_links (see: {Qernel::Link#assign_share})
  #
  # TODO refactor
  def calculate
    # TODO seb move @calculate to dataset
    Rails.logger.warn('Graph already calculated') if calculated?
    Rails.logger.info('Qernel::Graph#calculate')


    # FIFO stack of all the converters. Converters are removed from the stack after calculation.
    converter_stack = converters.clone
    self.finished_converters = []

    # delete_at is much faster as delete, that's why use #index rather than #detect
    while index = converter_stack.index(&:ready?)
      converter = converter_stack[index]
      converter.calculate
      self.finished_converters << converter_stack.delete_at(index)
    end

    self.finished_converters.map(&:input_links).flatten.each(&:assign_share)

    dataset_set(:calculated, true)

    unless converter_stack.empty?
      Rails.logger.warn "Following converters have not finished: #{converter_stack.map(&:full_key).join(', ')}"
    end
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
    @carriers ||= converters.map{|c| c.output_carriers}.flatten.uniq
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
    "Do not inspect. Because graph is to big that it takes a long time to inspect."
  end

  ##
  # optimizes calculation speed of graph by rearranging order of converters array
  #
  # @todo Calculate graph, and order converters array according to finished_converters
  def optimize_calculation_order
    # converters with preset_demand should be in the beginning of the array
    # makes calculating faster (as they are already ready?)

    copy = Marshal.load(Marshal.dump(self))
    copy.calculate
    copy.finished_converters.reverse.each_with_index do |converter, index|
      if old = converters.detect{|c| c.id == converter.id}
        converters.delete(old)
        converters.unshift(old)
      end
    end
  end

private

  def prepare_memoization
    groups.uniq.each {|key| group_converters(key)}
  end

  def build_lookup_hash
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
end

end
