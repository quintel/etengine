# frozen_string_literal: true

module Qernel
  module Reconciliation
    # A subordinate consumer has a demand curve which is influenced by the
    # demand curve of another node. The other node is typically a participant in
    # the merit order, and is called the "leader". In ETSource, the leader is
    # defined with "subordinate_to" attributes.
    #
    # An example is a H2 burner which serves as a backup to a power-to-heat
    # node. P2H will run in hours where there is excess electricity, calculated
    # by the merit order, and the burner should reduce its demand accordingly.
    #
    # Numerous restrictions apply:
    #
    #   * When initialized, the leader must have zero demand.
    #   * Both the leader and subordinate nodes must have an output slot of the
    #     same carrier, defined by the "subordinate_by_output" attribute in
    #     ETSource.
    #   * The leader node must have a output curve for the named output carrier.
    #
    class SubordinateConsumerAdapter < ConsumerAdapter
      def initialize(*)
        super
        @original_leader_demand = leader.demand
      end

      def demand_curve
        return super if leader.demand == @original_leader_demand

        leader_curve = SelfDemandProfile.curve(
          leader, "#{@config.subordinate_to_output}_output_curve"
        )

        # Convert the "influenced by" node's input to output, then to the
        # current nodes output back to input. This tells us demand of the
        # current node should be influenced by each unit of input in the
        # influencing node.
        conversion = leader_conversion

        super.map.with_index do |value, index|
          reduced = value - (leader_curve[index] * conversion)
          reduced.positive? ? reduced : 0.0
        end
      end

      private

      def calculate_carrier_demand
        unless leader.demand.zero?
          raise(
            "Cannot use \"#{@context.carrier}.subordinate_to\" on" \
            "#{@converter.key} when the leader/other node has a non-zero " \
            'demand.'
          )
        end

        super
      end

      # Internal: The conversion to be used to determine how much each unit of
      # the leader's input reduces input from this node.
      #
      # Returns a numeric.
      def leader_conversion
        self_input = @converter.input(@context.carrier).conversion

        self_output = @converter.output(
          @config.subordinate_to_output
        ).conversion

        self_input / self_output
      end

      def leader
        @leader ||= @context.graph.converter(@config.subordinate_to)
      end
    end
  end
end
