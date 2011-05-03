module Qernel

##
# handy mixin for things that get their values from graph data hash.
#
# It hides the implementation of how the qerrnel objects interact with the Qernel::Dataset
# object, so when the implementation changes, we just change it here.
#
# Use like this:
# include DatasetItem
#
module DatasetItem

  def self.compute_dataset_key(klass, id)
    "#{klass.name}_#{id}".downcase
  end

  # All qernel objects access dataset via their reference to graph (a Qernel::Graph)
  def dataset
    raise "#{self.class.name} has not defined a graph" if graph.nil?
    graph.dataset
  end

  # TODO ejp consider using blueprint_x_id
  # The dataset_key must be unique for the item and must be computable by the Qernel object that
  # references it. For now, we just use the QernelObject's id. In the future we should use the
  # corresponding blueprint item's id.
  #
  def dataset_key
    @dataset_key ||= DatasetItem.compute_dataset_key(self.class, id)
  end

  def to_dataset
    # TODO: only assign attributes defined in ConverterAPI::ATRIUBTES_USED + demand
    { dataset_key => attributes }
  end

  def [](attr_name)
    send(attr_name)
  end

  def []=(attr_name, value)
    send("#{attr_name}=", value)
  end

  private
  def get_my(attribute_name)
    dataset.andand.get(dataset_key, attribute_name)
  end

  def set_my(attribute_name, value)
    dataset.andand.set(dataset_key, attribute_name, value)
  end

  public
  module ClassMethods
    ##
    # assign a list of attributes to get from graph data
    def delegate_to_dataset(*attributes)
      attributes.each do |attr|
        attr_string = attr.to_s
        class_eval { define_method(attr_string) { get_my(attr_string) } }
        class_eval { define_method("#{attr_string}=") { |value| set_my(attr_string, value) } }
      end
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end


end

end
