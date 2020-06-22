module Qernel::Plugins
  # Calculates max_demand from the max_demands of the right.
  #
  # Issue: https://github.com/dennisschoenmakers/etsource/issues/77
  # Issue: https://github.com/dennisschoenmakers/etengine/issues/332
  # Issue: https://github.com/dennisschoenmakers/etengine/issues/331
  #
  # It uses the recursive_factor to calculate its value.
  class MaxDemandRecursive
    include Plugin

    # Use the same string each time to save on GC.
    RECURSIVE = 'recursive'.freeze

    before :calculation, :calculate_max_demand_recursive

    def calculate_max_demand_recursive
      @graph.nodes.each do |c|
        c.max_demand_recursive! if c.query.max_demand == RECURSIVE
      end
    end
  end # MaxDemandRecursive
end # Qernel::Plugins
