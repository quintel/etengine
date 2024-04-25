# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A consumer that uses a load curve based on a subordinate node in another time based
    # calculation. If an unmet-demand curve is used, the load_curve is first
    # converted to the input carrier of the current node.
    class SubordinateConsumerAdapter < ConsumerAdapter
      def initialize(*)
        super
        @subordinate_node = subordinate_node
      end

      def participant
        @participant ||=
          Merit::User.create(
            key: @node.key,
            load_curve: load_curve
          )
      end

      private

      def load_curve
        demand_curve = @context.curves.curve(
          @config.group,
          @subordinate_node
        )

        if @config.group.start_with?('unmet-demand')
          converted_demand_curve(demand_curve)
        else
          demand_curve
        end
      end

      def subordinate_node
        @context.graph.node(@config.subordinate_to).node_api
      end

      def converted_demand_curve(demand_curve)
        conversion = Qernel::Causality::Conversion.conversion(
          @node.node,
          @context.carrier,
          :input,
          carrier_to,
          :ouput
        )

        Qernel::Causality::LazyCurve.new do |frame|
          demand_curve[frame] / conversion
        end
      end

      def carrier_to
        Qernel::Causality::SelfDemandProfile
          .decode_name(@config.group, :unmet_demand)[:carrier_to]
      end
    end
  end
end
