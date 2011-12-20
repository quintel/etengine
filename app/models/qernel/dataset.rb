module Qernel
  # This is the qernel side of the Dataset ActiveRecord object.
  # When you run Dataset.find(...).to_qernel you'll get an instance of this class
  # and the data set will be loaded. LinkData, SlotData etc are merged in a single
  # large hash (+data+) with some major keys:
  # 
  # ruby-1.9.3-p0 :044 > Dataset.last.to_qernel.data.keys
  # => [:graph, :converter, :carrier, :link, :slot, :area]
  #
  # The DatasetAttribute module adds to the including class a set of methods to
  # access the related dataset values.
  # 
  # 
  # g = Dataset.new(id)
  # g << {:converter_converter_key => {...}}
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
  # def <<(group, hsh)
  #   @data[group] ||= {}
  #   hsh.each do |key, values|
  #     @data[group][key] = values.inject(@data[group][key] || {}) do |hsh,arr| 
  #       if arr.last.nil?
  #         hsh
  #       else
  #         hsh.merge arr.first.to_sym => arr.last
  #       end
  #     end
  #   end
  # end

  # this is the same as above, just more clear.
  # but has to be tested with gql test suites.
  def <<(group, key_hsh)
    @data[group] ||= {}
    key_hsh.each do |key, hsh|
      @data[group][key] ||= {}
      @data[group][key].merge!(hsh || {})
    end
  end
  alias_method :merge, :'<<'

  # @param [Array<Hash>]
  #
  def add(group, objects)
    raise "deprecated"
    objects.each do |obj|
      self.<< group, obj
    end
  end

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

  def set(group, object_key, attr_name, value)
    @data[group][object_key] ||= {}
    @data[group][object_key][attr_name] = value
  end

end

end
