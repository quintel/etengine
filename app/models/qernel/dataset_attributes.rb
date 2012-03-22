# This mixin is included by the qernel objects that have attributes defined
# in a dataset. See Qernel::Dataset for a general introduction about the 
# object. The Dataset object contains a huge hash with all the attributes
# of the area, carriers, converters etc of the graph. Those attributes are
# stored in the database in the dataset_*_data tables. Qernel::Dataset takes
# care of loading them into a single hash.
# Most of the methods defined in this mixin were made to access this hash.
#
# == Example:
#
#     class Qernel::Converter
#       include Qernel::DatasetAttributes
#
#       dataset_accessor :demand
#    
#       # above dataset_accessor generates the following methods:
#       def demand
#         dataset_get[:demand]
#       end
#    
#       def demand=(val)
#         dataset_set :demand, val
#       end
#     end
#
# So then you can access attributes like:
#
#     c = Qernel::Converter.new
#     c.demand 
#     c.dataset_get(:demand)
#
# == Careful: 
#
#     c[:demand]
# 
# will execute self.send(:demand), and not as you might assume
# dataset_get(:demand).
#
#
# == Overwriting dataset_accessors
#
#     class Qernel::Converter
#       include Qernel::DatasetAttributes
#
#       dataset_accessor :demand
#       
#       def demand; "hello world"; end
#     end
#
#     c = Qernel::Converter.new
#     c.dataset_set :demand, 300
#     c.dataset_get(:demand) # => 300
#     # But:
#     c.demand   # => "hello world"
#     c[:demand] # => "hello world"
#

module Qernel::DatasetAttributes

  def self.included(klass)
    klass.send(:attr_accessor, :object_dataset)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    # This creates a bunch of pseudo attr_reader / attr_writer methods
    # that delegate the storage to the Qernel::Dataset#data hash.
    # In most Qernel objects you will see this method called with a list
    # of the attributes stored in the dataset.    
    def dataset_accessors(*dataset_attributes)
      dataset_attributes.flatten.each do |attr_name|
        attr_name_sym = attr_name.to_sym
        define_method attr_name do
          dataset_get attr_name_sym
        end
        define_method "#{attr_name}=" do |value|
          dataset_set attr_name_sym, value
        end
      end
    end

    def dataset_group
      @dataset_group ||= self.name.split("::").last.downcase.to_sym
    end

    def compute_dataset_key(id)
      id
    end
  end

  # For testing only
    def with(hsh)
      @object_dataset = hsh
      self
    end
  
  # The dataset belongs to the graph and the Qernel object belongs to the graph:
  # let's get the dataset then. This assumes that the Qernel object has already
  # been assigned a graph and the graph has a dataset too. Don't forget this when
  # you're working with the console.
  def dataset
    graph && graph.dataset
  end

  def dataset_group
    self.class.dataset_group
  end

  def graph
    raise "#{self.class.name} needs to define a 'graph' method, as it includes DatasetAttributes"
  end

  def dataset_key
    @dataset_key ||= self.class.compute_dataset_key(id)
  end

  def reset_object_dataset
    @object_dataset = nil
  end

  # Here we make the object attributes a member of the object itself.
  # The dataset_get/fetch methods act on this variable (which, btw, is
  # made accessible with the attr_accessor at the beginning of this mixin)
  def assign_object_dataset
    if dataset
      @object_dataset = (dataset.data[dataset_group][dataset_key] ||= {})
    end
  rescue => e
    raise "Qernel::Dataset: missing dataset item for #{dataset_group.inspect} #{dataset_key}. #{e.inspect}"
  end

  # HANDLE_NIL_SECURLY = true has better output for debugging
  # HANDLE_NIL_SECURLY = false is 50 ms faster. but harder to debug if problem occurs
  HANDLE_NIL_SECURLY = true 
  def dataset_fetch_handle_nil(attr_name, handle_nil_securly = false, &block)
    if !graph.calculated? # do not memoize when graph has not finished calculating.
      yield rescue nil
    elsif object_dataset.has_key?(attr_name)
      object_dataset[attr_name]
    elsif HANDLE_NIL_SECURLY || handle_nil_securly
      object_dataset[attr_name] = handle_nil(attr_name, &block)
    else
      object_dataset[attr_name] = yield rescue nil
    end
  end

  def handle_nil(attr_name, rescue_with = nil, &block)
    if required_attributes_contain_nil?(attr_name)
      nil
    else
      yield
    end
  end

  # Memoization
  #
  def dataset_fetch(attr_name, &block)
    if !graph.calculated? # do not memoize when graph has not finished calculating.
      yield
    elsif object_dataset.has_key?(attr_name)
      object_dataset[attr_name]
    else
      object_dataset[attr_name] = yield
    end
  end

  def dataset_delete(attr_name)
    object_dataset.delete(attr_name)
  end

  # @param attr_name [Symbol]
  def dataset_set(attr_name, value)
    object_dataset[attr_name] = value
    # dataset.set(dataset_group, dataset_key, attr_name, value)
  end

  # @param attr_name [Symbol]
  def dataset_get(attr_name)
    object_dataset[attr_name]
  rescue => e
    raise "#{dataset_key} #{attr_name} not found: #{e.message}" 
  end

  def [](attr_name)
    send(attr_name)
  end

  def []=(attr_name, value)
    # Converter overrides the normal dataset_accessors with custom stuff for demand
    # calculation. so we can stack multiple demands together
    #
    # attr_name_sym = attr_name.to_sym
    # if attr_name_sym === :preset_demand
    #  send("#{attr_name}=", value)
    # else
      self.send("#{attr_name}=", value)
    # end
  end
end
