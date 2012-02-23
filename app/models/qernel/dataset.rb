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
  attr_accessor :data
  attr_reader :id, :data

  def initialize(id = nil)
    if id.nil?
      Rails.logger.warn("Qernel::Dataset initialized without a id. Can lead to conflicts with Gquery Caching.")
    end
    @id = id
    @data = {:graph => {:graph => {}}}
  end

  def time_curves
    @data[:time_curves]
  end

  def set(group, object_key, attr_name, value)
    @data[group][object_key] ||= {}
    @data[group][object_key][attr_name] = value
  end

end

end
