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


  module ClassMethods
    # used now in api/v3/converter.rb. Implement this when needed.
    def calculation_methods
      []
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end

end
