
##
#
#
#
#
module Qernel::DatasetAttributes

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def dataset_accessors(dataset_attributes)
      dataset_attributes.each do |attr_name|
        define_method attr_name do
          dataset_get attr_name.to_sym
        end

        define_method "#{attr_name}=" do |value|
          dataset_set attr_name.to_sym, value
        end
      end
    end

    def compute_dataset_key(klass, id)
      "#{klass}_#{id}".downcase.to_sym
    end
  end

  # TODO ejp consider using blueprint_x_id
  # The dataset_key must be unique for the item and must be computable by the Qernel object that
  # references it. For now, we just use the QernelObject's id. In the future we should use the
  # corresponding blueprint item's id.
  #
  def compute_dataset_key
    dataset_key
  end

  def dataset
    raise "#{self.class.name} has not defined a graph" if graph.nil?
    graph.dataset
  end

  def graph
    raise "#{self.class.name} needs to define a 'graph' method, as it includes DatasetAttributes"
  end

  def dataset_key
    @dataset_key ||= self.class.compute_dataset_key(self.class, id)
  end

  def dataset_fetch(attr_name, &block)
    dataset.memoize(self, attr_name, &block)
  end

  def dataset_set(attr_name, value)
    dataset.set(dataset_key, attr_name.to_sym, value)
    value
  end
  alias_method :write_dataset_attribute, :dataset_set

  def dataset_get(attr_name)
    dataset.get(dataset_key, attr_name.to_sym)
  end
  alias_method :read_dataset_attribute, :dataset_get

  def [](attr_name)
    send(attr_name)
  end

  def []=(attr_name, value)
    send("#{attr_name}=", value)
  end
end
