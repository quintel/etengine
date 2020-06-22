# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sets up and fully-calculates the Merit order. After the graph has been
    # calculated, the graph demand is supplied to the Merit gem to determine how
    # to fairly assign loads depending on cost.
    #
    # After the merit order has been calculated, it's producer loads are
    # assigned back to the graph, and the graph will be recalculated.
    class Manager < Qernel::Plugins::SimpleMeritOrder
      # A list of types of merit order producers to be supplied to the M/O.
      def participant_types
        %i[consumer flex producer].freeze
      end

      def setup
        super
        setup_flex_groups
      end

      # Internal: After the first graph is calculated, demands are passed into
      # the Merit order to determine in which order to run the plants. The
      # results are stored for future use.
      def run(lifecycle)
        lifecycle.must_recalculate!
      end

      # Internal: Takes loads and costs from the calculated Merit order, and
      # installs them on the appropriate nodes in the graph. The updated
      # values will be used in the recalculated graph.
      #
      # Returns nothing.
      def inject_values!
        each_adapter(&:inject!)
        set_dispatchable_positions!
        inject_graph_values!
      end

      private

      # Internal: Sets the position of each dispatchable in the merit order -
      # according to their marginal cost - so that this may be communicated to
      # other applications.
      #
      # Returns nothing.
      def set_dispatchable_positions!
        dispatchables =
          @order.participants.dispatchables.select do |participant|
            # Flexible technologies are classed as dispatchable but should not
            # be assigned a position.
            adapter(participant.key).config.subtype == :dispatchable
          end

        dispatchables.each.with_index do |participant, position|
          adapter(participant.key)
            .node[:merit_order_position] = position + 1
        end
      end

      def setup_flex_groups
        flex_groups.each do |key, config|
          order.participants.flex_groups.define(
            FlexGroupBuilder.build(key, config)
          )
        end
      end

      def flex_groups
        {}
      end

      def household_heat
        HouseholdHeat.new(@graph)
      end

      # Internal: Sets global values on the graph object after calculation.
      def inject_graph_values!
      end
    end
  end
end
