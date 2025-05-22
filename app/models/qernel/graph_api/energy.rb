# frozen_string_literal: true

module Qernel
  module GraphApi
    # An API specific to the energy graph.
    class Energy
      include Common

      def use_merit_order_demands?
        Qernel::Plugins::Causality.enabled?(graph)
      end

      # NON GQL-able

      def area_footprint
        graph.group_nodes(:bio_footprint_calculation).map do |node|
          slot = node.outputs.reject(&:loss?).first
          demand = node.demand || 0.0

          if (prod = slot.carrier.typical_production_per_km2)
            demand / prod
          else
            0.0
          end
        end.flatten.compact.sum
      end

      # Demand of electricity for all final demand nodes (MWh)
      def final_demand_for_electricity
        group_demand_for_electricity(:final_demand_group)
      end

      # Demand of electricity for all nodes which do not belong to the final_demand_group but
      # nevertheless consume electricity. (MWh)
      def non_final_demand_for_electricity
        group_demand_for_electricity(:non_final_electricity_demand_nodes)
      end

      # Demand of electricity for all nodes which belong to the named group.
      #
      # Returns a Numeric representing energy in MWh
      def group_demand_for_electricity(group)
        graph
          .group_nodes(group)
          .map { |conv| conv.node_api.input_of_electricity }
          .compact.sum
      end

      # Public: The demand of electricity in the entire graph, including use in the energy sector
      # and losses caused by no exports.
      #
      # Returns a numeric. (MWh)
      def total_demand_for_electricity
        final_demand_for_electricity +
          non_final_demand_for_electricity +
          electricity_losses_if_export_is_zero
      end

      # Public: Given a +demand+ placed on the graph, and a maximum per-hour load +capacity+,
      # determines the proportion of hours where demand exceeds production capacity.
      #
      # capacity - The total installed capacity, in MWh.
      # excludes - Nodes keys whose profiled demands should be subtracted from the total demand
      #            curve prior to calculating LOLE. See merit#123 for an example of why this may be
      #            desirable.
      #
      # For example
      #
      #   node.loss_of_load_expectation(120, 100)
      #   # => 130
      #   # This means that for 130 hours in the year, the demand (120 MW) demand
      #   # exceeded available supply of 100 MW.
      #
      # Returns a Integer representing the number of hours where capacity was exceeded.
      def loss_of_load_expectation(capacity, excludes = [])
        order = graph.plugin(:merit).order
        order.lole.expectation(order.demand_curve, capacity, excludes)
      end

      # Public: Returns number of excess load events for a certain duration. Takes one single
      # duration as an Integer or Float
      #
      # Returns an Integer
      def number_of_excess_events(duration, excludes = [])
        graph.plugin(:merit).order.excess(excludes).number_of_events(duration)
      end

      # Public: Returns number of excess load events for multiple durations Takes a set of durations
      # in an Array
      #
      # Returns an Array
      def group_of_excess_events(durations = [], excludes = [])
        graph.plugin(:merit).order.excess(excludes).event_groups(durations)
      end

      # Public: Returns total number of hours there was excess
      #
      # Returns an Integer (hours)
      def total_number_of_excess_events(excludes = [])
        graph.plugin(:merit).order.excess(excludes).total_number_of_events
      end

      # Public: Returns number of blackout hours
      #
      # Returns an Integer (hours)
      def number_of_power_shortage_hours
        graph.plugin(:merit).order.blackout.number_of_hours
      end

      # Public: Returns the peak of blackout hours, defined as the largest single hour deficit
      #
      # Returns a Numeric (MW)
      def peak_of_power_shortage_hours
        graph.plugin(:merit).order.blackout.peak
      end

      # Public: Returns volume of blackout hours, defined as the sum of deficit hours
      #
      # Returns an Numeric (MWh)
      def volume_of_power_shortage_hours
        graph.plugin(:merit).order.blackout.volume
      end

      # Public: Builds a model of the electricity network.
      #
      # Returns an object responding to the name of each layer in the network.
      def electricity_network
        fetch(:electricity_network) do
          curve_helper = graph.plugin(:merit).curves

          Closud::Queryable.new(
            Closud.build(graph),
            ->(curve) { curve_helper.derotate(curve) }
          )
        end
      end

      # Computes the electricity losses AS IF there were no exports.
      #
      # This is accomplished by using the (fixed) conversion efficiencies of the HV network for
      # electricity (effE) and losses (effL) and the expected total demand of the network IF the
      # merit order is activated (transformer_demand + export (== 0)).
      #
      #              +--------+
      #              | Export | <-+
      #              +--------+   |
      #                +------+   |
      #                | Loss | <-+
      #                +------+   |   +------------+
      #                           +-- | HV Network |
      #   +-------------------+   |   +------------+
      #   | Own use of sector | <-+
      #   +-------------------+   |
      #      +----------------+   |
      #      | MV transformer | <-+
      #      +----------------+
      #
      # To find the loss IF export is zero, we use the fact that the ratio of loss and electricity
      # coming from the HV network is fixed.
      #
      #   loss / (transformer_demand + export) == effL / effE
      #
      # Setting export = 0 (as would be the case if the MO module is enabled) gives the loss:
      #
      #   loss = transformer_demand * effL / effE
      #
      # Returns a numeric: the network losses for the electricity net. (MWh)
      def electricity_losses_if_export_is_zero
        transformer_demand     = graph.node(:energy_power_transformer_mv_hv_electricity).demand
        own_use_of_sector      = energy_sector_own_use_electricity
        node                   = graph.node(:energy_power_hv_network_electricity)
        conversion_loss        = node.output(:loss).conversion
        conversion_electricity = node.output(:electricity).conversion

        return 0.0 if conversion_electricity.zero?

        (transformer_demand + own_use_of_sector) * conversion_loss / conversion_electricity
      end

      private

      # Demand of electricity of the energy sector itself (not included in
      # final_demand_for_electricity)  (MWh)
      def energy_sector_own_use_electricity
        graph.node(:energy_power_sector_own_use_electricity).demand
      end
    end
  end
end
