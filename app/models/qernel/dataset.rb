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

  def initialize(id = nil)
    if id.nil?
      Rails.logger.warn("Qernel::Dataset initialized without a id. Can lead to conflicts with Gquery Caching.")
    end
    @id = id
    @data = {:graph => {:graph => {}}}
    @memoized_data = {}
  end

  ##
  # Add all the data for a graph in one shot. Common case initializer.
  #
  # @param converter_data [Array<::Converter>]
  # @param carrier_data [Array<::Carrier>]
  # @param link_data [Array<::Link>]
  # @param slot_data [Array<::Slot>]
  # @param area_data [Array<::Area>]
  #
  def add_dataset(converter_data, carrier_data, link_data, slot_data, area_data)
    add_data :converter, converter_data
    add_data :carrier, carrier_data
    add_data :link, link_data
    add_data :slot, slot_data
    add_data :area, area_data
  end

  ##
  # Adds the hash to the @data. Removes key/value pairs where value is nil
  #  for better performance.
  #
  # @param [Hash]
  #
  def <<(group, hsh)
    @data[group] ||= {}
    hsh.each do |key, values|
      @data[group][key] = values.inject({}) do |hsh,arr| 
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
  def add(group, objects)
    objects.each do |obj|
      self.<< group, obj
    end
  end

  ##
  # adds a collection of things that respond_to :to_qernel.dataset_key
  # @param [Array<#dataset_key and #attributes>] data
  #
  def add_data(group, collection)
    [collection].flatten.each do |item|
      raise "cannot add a #{item.class} to graph data" unless item.respond_to? :dataset_key
      attrs = item.respond_to?(:dataset_attributes) ? item.dataset_attributes : item.attributes
      self.<<(group, item.dataset_key => attrs)
    end
  end

end

end
