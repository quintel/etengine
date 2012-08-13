module Qernel::Plugins
  # Calculates max_demand from the max_demands of the right.
  #
  # Issue: https://github.com/dennisschoenmakers/etsource/issues/77
  # Issue: https://github.com/dennisschoenmakers/etengine/issues/332
  # Issue: https://github.com/dennisschoenmakers/etengine/issues/331
  #
  # It uses the recursive_factor to calculate it's value.
  module MaxDemandRecursive
    extend ActiveSupport::Concern

    included do |variable|
      set_callback :calculate, :before, :calculate_max_demand_recursive
    end

    def calculate_max_demand_recursive
      instrument("qernel.calculate_max_demand_recursive") do
        converters.each do |c|
          c.max_demand_recursive! if c.query.max_demand == 'recursive'
        end
      end
    end
    
  end
end
