module Qernel::Plugins
  module Fever
    # Provides demand curves appropriate for a scenario.
    class Curves
      def initialize(graph)
        @graph = graph
      end

      def household_heat
        merit_curves = @graph.plugin(:time_resolve).merit.curves

        Qernel::Plugins::Merit::Util.add_curves([
          merit_curves.old_household_space_heating_demand,
          merit_curves.new_household_space_heating_demand
        ])
      end
    end
  end
end
