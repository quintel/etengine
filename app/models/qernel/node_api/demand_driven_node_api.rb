# frozen_string_literal: true

module Qernel
  module NodeApi
    # Provides a slightly different NodeApi which calculates the full load period as a function of
    # demand, instead of based on the number of units.
    #
    # NodeApi assumes that, as demand changes, the number of units changes to compensate. But in
    # some cases this is nonsensical; for example, if housing insulation is improved, it makes no
    # sense for the reduced demand to manifest in fewer heating appliances. Instead, it is likely
    # that the same number of appliances will exist, but that they will be used less often.
    class DemandDrivenNodeApi < EnergyApi
      # How many seconds a year the node runs at full load. Varies
      # depending on the demand.
      def full_load_seconds
        supply = nominal_capacity_heat_output_per_unit * number_of_units

        return 0.0 if supply.zero?

        ((demand_of_steam_hot_water || 0.0) + (demand_of_useable_heat || 0.0)) / supply
      rescue RuntimeError
        nil
      end

      # How many hours a year the node runs at full load. Varies depending on the demand.
      #
      # Note that dataset_fetch is not used otherwise we end up pulling the (incorrect) value from
      # the dataset, instead of using the dynamic value calculated in full_load_seconds.
      def full_load_hours
        full_load_seconds ? full_load_seconds / 3600 : nil
      end

      # Demand-driven nodes have a semi-fixed number of units which changes directly based on user
      # input.
      #
      # In order to determine the number of units, we first find out what share of demand is
      # satisfied in the demanding node by this node. For example, if the sum of output share edges
      # is 0.2, it is assumed that this node accounts for 20% of the "technology share".
      #
      # Finally, the number of units is adjusted according to how many households are supplied with
      # heat. For example, if 50% of households are supplied with energy from the node, but each
      # unit provides energy for 100 homes, the number_of_units will equal 50% of
      # number_of_residences divided by 100.
      #
      def number_of_units
        fetch(:number_of_units, false) do
          heat_edges = demand_driven_edges

          return 0.0 if heat_edges.empty?

          tech_share = sum_unless_empty(heat_edges.map(&:share)) || 0
          tech_share = 0.0 if tech_share.abs < 1e-6
          units      = tech_share * (area.number_of_residences || 0)
          supplied   = households_supplied_per_unit

          # Sanity check; if households_supplied_per_unit is zero, it may
          # simply be that a value wasn't set, so we instead assume that it
          # should be set to 1.
          supplied = 1.0 if supplied.zero?

          units / supplied
        rescue RuntimeError
          nil
        end
      end

      private

      # Internal: Finds and memoizes the edges used to determine the demand-driven attributes.
      #
      # If the node is connected with a single output edge to an "aggregator" node, the aggregator's
      # output edges are instead used.
      #
      # Returns an array of edges.
      def demand_driven_edges
        suitable_edges = demand_edges_for(node)

        if suitable_edges.any? && node.groups.include?(:aggregator_producer)
          return demand_edges_for(suitable_edges[0].lft_node)
        end

        suitable_edges
      end

      def demand_edges_for(conv)
        conv.output_edges.select do |edge|
          edge.carrier && (edge.useable_heat? || edge.steam_hot_water?)
        end
      end
    end
  end
end
