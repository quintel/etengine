module Qernel::Plugins
  module Merit
    class HouseholdPowerToHeatAdapter < PowerToHeatAdapter
      private

      def excess_share
        1.0
      end

      def reserve_decay
        curves = @graph.plugin(:merit).curves

        elec_hw_demand = curves.household_hot_water_demand
        elec_hw_share  = curves.share_of_electricity_in_household_hot_water

        elec_performance =
          (1.0 / curves.household_hot_water_cop) * elec_hw_share

        # Demand is calculated by Merit before computing decay. Therefore we can
        # only subtract demand from the next step.
        stop_at = elec_hw_demand.length - 2

        lambda do |point, available|
          hw_demand = elec_hw_demand.get(point + 1)
          wanted    = hw_demand / elec_performance
          use       = available > wanted ? wanted : available

          # Subtract demand from the appropriate profiles.
          if point < stop_at && use > 0
            # Defines electricity saved by not running the electrical hot water
            # producers. Needs to account for the share of electrical producers
            # (since P2H reduces all heat demand, not just that from elec.) and
            # the difference in performance between P2H and other providers
            # (e.g. one unit of heat may require 0.5 units of electricity).
            elec_saving = use * elec_performance

            if hw_demand < elec_saving
              # More P2H available than needed, reduce demand to zero.
              elec_hw_demand.set(point + 1, 0.0)
            else
              elec_hw_demand.set(point + 1, hw_demand - elec_saving)
            end
          end

          use
        end
      end
    end # PowerToHeatAdapter
  end # Merit
end
