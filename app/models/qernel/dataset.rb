module Qernel

##
#
# g = Dataset.new(id)
# g << {:converter_converter_key => {...}}
#
#
class Dataset
  attr_accessor :time_curves
  attr_reader :id, :data

  def memoize(object, attr_name, &block)
    @memoized_data[object] ||= {}
    @memoized_data[object][attr_name] ||= yield
  end

  def initialize(id = nil)
    if id.nil?
      Rails.logger.warn("Qernel::Dataset initialized without a id. Can lead to conflicts with Gquery Caching.")
    end
    @id = id
    @data = {:graph => {}}
    @memoized_data = {}
  end

  ##
  # Add all the data for a graph in one shot. Common case initializer.
  #
  # @param converter_data [Array<::Converter>]
  # @param carrier_data [Array<::Carrier>]
  # @param link_data [Array<::Link>]
  # @param slot_data [Array<::Slot>]
  #
  def add_graph(converter_data, carrier_data, link_data, slot_data)
    add_data converter_data
    add_data carrier_data
    add_data link_data
    add_data slot_data
  end

  ##
  # Adds the hash to the @data. Removes key/value pairs where value is nil
  #  for better performance.
  #
  # @param [Hash]
  #
  def <<(hsh)
    hsh.each do |key, values|
      @data[key.to_sym] = values.inject({}) do |hsh,arr| 
        if arr.last.nil?
          hsh
        else
          hsh.merge arr.first.to_sym => arr.last
        end
      end
    end
  end

  ##
  #
  #
  # @param [Array<Hash>]
  #
  def add(objects)
    objects.each do |obj|
      self.<< obj
    end
  end

  ##
  # adds a collection of things that respond_to :to_qernel.dataset_key
  # @param [Array<#dataset_key and #attributes>] data
  #
  def add_data(collection)
    [collection].flatten.each do |item|
      raise "cannot add a #{item.class} to graph data" unless item.respond_to? :dataset_key
      attrs = item.respond_to?(:dataset_attributes) ? item.dataset_attributes : item.attributes
      self.<<(item.dataset_key => attrs)
    end
  end

  # In the dataset values that are nil do not get a key. So it should return nil.
  #
  def get(object_key, attr_name)
    #raise "Dataset#get #{object_key} #{attr_name}" unless @data.has_key?(object_key.to_sym)
    # if @data[object_key].has_key?(attr_name)
      @data[object_key][attr_name]
    # else
      nil
    # end
  end

  def set(object_key, attr_name, value)
    @data[object_key] ||= {}
    @data[object_key][attr_name] = value
  end

end

end
