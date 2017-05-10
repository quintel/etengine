module Qernel::Plugins
  module Merit
    class PowerToHeatAdapter < StorageAdapter
      def inject!
        target = target_api

        full_load_hours =
          participant.production * output_efficiency / (
            participant.input_capacity_per_unit *
            participant.number_of_units *
            3600
          )

        if ! full_load_hours || full_load_hours.nan?
          full_load_seconds = full_load_hours = 0.0
        else
          full_load_seconds = full_load_hours * 3600
        end

        target[:full_load_hours]   = full_load_hours
        target[:full_load_seconds] = full_load_seconds

        target.demand =
          full_load_seconds *
          @converter.input_capacity *
          participant.number_of_units
      end

      private

      def producer_attributes
        attrs = super

        # Remove from the storage ("buffer") as much as possible to satisfy the
        # demand profile.
        decay = subtraction_profile
        curves = @graph.plugin(:merit).curves

        elec_hw_demand = curves.household_hot_water_demand

        elec_performance =
          curves.household_hot_water_cop /
          curves.share_of_electricity_in_household_hot_water

        # producer_cop = curves.household_hot_water_cop
        # producer_share = curves.share_of_electricity_in_household_hot_water

        # Demand is calculated by Merit before computing decay. Therefore we can
        # only subtract demand from the next step.
        stop_at = elec_hw_demand.length - 2

        attrs[:decay] = lambda do |point, available|
          wanted = decay.get(point)

          use = available > wanted ? wanted : available

          # Subtract demand from the appropriate profiles.
          if point < stop_at && use > 0
            hw_demand = elec_hw_demand.get(point + 1)

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

        # Do not emit anything; it has been converted to hot water.
        attrs[:output_capacity_per_unit] = 0.0

        attrs
      end

      def subtraction_profile
        demand_profile *
          @graph.converter(@config.demand_source).converter_api.demand
      end

      def demand_profile
        ::Merit::LoadProfile.load(
          @dataset.load_profile_path(@config.demand_profile)
        )
      end
    end # PowerToHeatAdapter
  end # Merit
end
