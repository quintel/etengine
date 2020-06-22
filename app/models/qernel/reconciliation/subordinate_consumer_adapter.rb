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

        @original_carrier_demand = orig_calculate_carrier_demand
        @original_leader_demand = leader.demand
      end

      # Public: The demand curve for the subordinate.
      #
      # The curve is calculated by taking the original curve (based on the
      # configured profile and original carrier demand) and subtracting from it
      # the energy which is no longer needed due to supply from the leader node.
      #
      # Returns an array.
      def demand_curve
        return @demand_curve if @demand_curve

        if unchanged_leader?
          @demand_curve = original_demand_curve
          return @demand_curve
        end

        leader_curve = Causality::SelfDemandProfile.curve(
          leader.node_api, "#{@config.subordinate_to_output}_output_curve"
        )

        conversion = leader_conversion

        @demand_curve =
          original_demand_curve.map.with_index do |value, index|
            reduced = value - (leader_curve[index] * conversion)
            reduced.positive? ? reduced : 0.0
          end
      end

      private

      def demand_phase
        # Calculation of carrier demand depends on the leader having a curve,
        # which comes from Merit/Fever.
        :dynamic
      end

      def unchanged_leader?
        leader.demand == @original_leader_demand
      end

      # Internal: The demand curve without subtracting the energy supplied by
      # the leader.
      def original_demand_curve
        demand_profile * @original_carrier_demand
      end

      # The original method for calculating carrier demand (demand times the
      # conversion) is used when initializing the adapter.
      alias_method :orig_calculate_carrier_demand, :calculate_carrier_demand

      # Internal: When the leader demand has changed, we must dynamically
      # recalculate the demand to account for energy now provided by the leader.
      def calculate_carrier_demand
        unchanged_leader? ? @original_carrier_demand : (demand_curve.sum * 3600)
      end

      # Internal: The conversion to be used to determine how much each unit of
      # the leader's input reduces input from this node.
      #
      # Returns a numeric.
      def leader_conversion
        self_input = @node.input(@context.carrier).conversion

        self_output = @node.output(
          @config.subordinate_to_output
        ).conversion

        self_input / self_output
      end

      def leader
        @leader ||= @context.graph.node(@config.subordinate_to)
      end
    end
  end
end
