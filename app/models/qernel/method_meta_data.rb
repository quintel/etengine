module Qernel

module MethodMetaData

  # Sums all non-nil values.
  # Returns nil if all values are nil.
  #
  # @param [Array<Float,nil>] Values to sum
  # @return [Float,nil] The sum of all values. nil if all values are nil
  #
  def sum_unless_empty(values)
    values = values.compact
    values.empty? ? nil : values.sum
  end

  # Returns the attribute names of given method.
  # if no method_name given return values of required by the caller_method
  #
  # @return [Array<Symbol>] required attribute_names of given method
  #
  def required_attributes_for_method(method_name = nil)
    method_name ||= caller_method
    self.class.required_attributes_for_method(method_name)
  end

  # Returns the values of given method.
  # if no method_name given return values of required by the caller_method
  #
  # @return [Array<Float>] required values of given method
  #
  def values_for_method(method_name = nil)
    # TODO remove caller_method as it is very slow
    method_name ||= caller_method
    required_attributes_for_method(method_name).
      map{|attr_key| self.send(attr_key) }
  end

  # Is any of the required attributes nil.
  #
  # @return [true,false]
  #
  def required_attributes_contain_nil?(method_name = nil)
    # TODO remove caller_method as it is very slow
    method_name ||= caller_method
    values_for_method(method_name).any?(&:nil?)
  end



  module ClassMethods
    def register_calculation_method(keys)
      registered_calculation_methods = [registered_calculation_methods, keys].flatten
    end

    def registered_calculation_methods
      @registered_calculation_methods ||= []
    end

    def calculation_methods
      required_attributes.keys + registered_calculation_methods
    end

    # Hash of :method_name => required_attributes_for_method
    #
    def required_attributes
      @required_attributes ||= {}
    end

    # @param method_name [String,Symbol]
    # @return [Array<Symbol>] attributes/methods used by given method
    #
    def required_attributes_for_method(method_name)
      required_attributes[method_name.to_sym] || []
    end

    # @param method_name [Symbol]
    # @param attributes [Array<Symbol>]
    #
    def attributes_required_for(method_name, attributes)
      required_attributes[method_name] = attributes
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end

end
