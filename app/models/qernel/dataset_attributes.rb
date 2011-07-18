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

  def dataset
    graph.dataset
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

  def assign_object_dataset
    @object_dataset = (dataset.data[dataset_group][dataset_key] ||= {})
  end

  def dataset_fetch_handle_nil(attr_name, &block)
    if object_dataset.has_key?(attr_name)
      object_dataset[attr_name]
    else
      object_dataset[attr_name] = yield rescue nil
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

  # @param attr_name [Symbol]
  def dataset_set(attr_name, value)
    object_dataset[attr_name] = value
  end

  # @param attr_name [Symbol]
  def dataset_get(attr_name)
    object_dataset[attr_name]
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
