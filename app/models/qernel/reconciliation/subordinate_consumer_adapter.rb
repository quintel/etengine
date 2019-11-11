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
    #   * When initialized, the leader must have no demand.
    #   * Both the leader and subordinate nodes must have an output slot of the
    #     same carrier, defined by the "subordinate_by_output" attribute in
    #     ETSource.
    #   * The leader node must have a curve assigned to an attribute whose name
    #     is configured in ETSource with the "subordinate_by_input" attribute. An
    #     input slot of the same carrier should also exist.
    #
    class SubordinateConsumerAdapter < ConsumerAdapter
      def initialize(*)
        super
        @original_leader_demand = leader.demand
      end

      def demand_curve
        return super if leader.demand == @original_leader_demand

        leader_curve = leader.query.public_send(
          "#{@config.subordinate_input}_input_curve"
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
        leader_input = leader.input(@config.subordinate_input).conversion
        leader_output = leader.output(output_carrier).conversion

        self_input = @converter.input(@context.carrier).conversion
        self_output = @converter.output(output_carrier).conversion

        (leader_output / leader_input) * (self_input / self_output)
      end

      # Internal: Attempts to automatically determine the output carrier both
      # the leader and subordinate have in common. Raises an error if they have
      # more than one carrier in common.
      def output_carrier
        return @config.subordinate_output if @config.subordinate_output

        common =
          leader.outputs.map(&:carrier).reject(&:loss?) &
          @converter.outputs.map(&:carrier).reject(&:loss?)

        return common.first.key if common.one?

        raise(
          'Cannot automatically determine the ' \
          "\"#{@context.carrier}.subordinate_output\" carrier for " \
          "#{@converter.key}, both nodes have several output carriers in " \
          'common. Please specify the carrier manually in the node document.'
        )
      end

      def leader
        @leader ||= @context.graph.converter(@config.subordinate_to)
      end
    end
  end
end
