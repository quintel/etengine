##
#
#
#
#
module Qernel::DatasetAttributes

  def self.included(klass)
    klass.send(:attr_accessor, :object_dataset)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def dataset_accessors(dataset_attributes)
      dataset_attributes.each do |attr_name|
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

  # overwritable method
  def after_assign_object_dataset
  end

  def assign_object_dataset
    if dataset
      @object_dataset = (dataset.data[dataset_group][dataset_key] ||= {})
    end
    after_assign_object_dataset
  end

  #def object_dataset
  #  @object_dataset ||= (dataset.data[dataset_group][dataset_key] ||= {})
  #end

  # HANDLE_NIL_SECURLY = true has better output for debugging
  # HANDLE_NIL_SECURLY = false is 50 ms faster. but harder to debug if problem occurs
  HANDLE_NIL_SECURLY = true 
  def dataset_fetch_handle_nil(attr_name, handle_nil_securly = false, &block)
    if object_dataset.has_key?(attr_name)
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
    if object_dataset.has_key?(attr_name)
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
    raise "#{dataset_key} #{attr_name} not found" 
  end

  def [](attr_name)
    send(attr_name)
  end

  def []=(attr_name, value)
    # Converter overrides the normal dataset_accessors with custom stuff for demand
    # calculation. so we can stack multiple demands together
    #
    # attr_name_sym = attr_name.to_sym
    # if attr_name_sym === :preset_demand || attr_name_sym === :municipality_demand
    #  send("#{attr_name}=", value)
    # else
      self.send("#{attr_name}=", value)
    # end
  end
end
