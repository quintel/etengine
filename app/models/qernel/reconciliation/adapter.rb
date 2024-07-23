# frozen_string_literal: true

module Qernel
  module Reconciliation
    # Converts a Qernel::Node to a Reconciliation adapter and back again.
    class Adapter
      def self.adapter_for(node, context)
        type = context.node_config(node).type

        klass =
          case type
          when :consumer
            ConsumerAdapter.factory(node, context)
          when :export
            ExportAdapter
          when :producer
            ProducerAdapter.factory(node, context)
          when :import
            ImportAdapter
          when :storage
            StorageAdapter
          when :transformation
            TransformationAdapter
          else
            raise 'Unknown reconciliation participant type for ' \
                  "#{node.key}: #{type.inspect}"
          end

        klass.new(node, context)
      end

      def initialize(node, context)
        @node = node
        @context = context
        @config = context.node_config(node)
      end

      def setup(phase:)
        @carrier_demand = calculate_carrier_demand if phase == demand_phase
      end

      def carrier_demand
        @carrier_demand || raise("carrier_demand not yet calulated for #{@node.key}")
      end

      def demand_curve
        @demand_curve ||=
          if carrier_demand.zero?
            Merit::Curve.new([0.0] * 8760)
          else
            demand_profile * carrier_demand
          end
      end

      def inspect
        "#<#{self.class.name} #{@node.key.inspect}>"
      end

      # Public: Receives the reconciliation calculator and makes changes to the
      # graph according to the behaviour of the adapter in the calculation.
      #
      # Override in subclasses as needed.
      #
      # Returns nothing.
      def inject!(_calculator); end

      # Public: Performs actions prior to the recalculation of the graph triggered by Causality.
      #
      # Note that most adapters will not have been configured - let alone calculated - at this
      # point. Changes to the graph are only possible when you are sure the adapter and its node
      # will not be influenced by any change resulting from Merit/Fever.
      #
      # You should only implement this method when the `demand_phase` is `:manual` and you will
      # trigger the adapter set-up manually.
      #
      # Returns nothing.
      def before_graph_recalculation!; end

      private

      def calculate_carrier_demand
        raise NotImplementedError
      end

      # Internal: Defines when in the time_resolve calculation to create the
      # demand curve.
      #
      # Most participants in Reconciliation have static curves which are a
      # function of a load profile and the demand of the node. The demand
      # curve of these participants must be created before Merit detaches the
      # dataset, afterwhich the node demand will be zero (pending
      # recalculation). These are :static.
      #
      # Others only have a correct demand curve _after_ the Merit calculation,
      # such as power-to-gas. These are :dynamic.
      #
      # Returns a Symbol.
      def demand_phase
        @config.profile.to_s.strip.start_with?('self') ? :dynamic : :static
      end

      # Internal: Creates the profile describing the shape of the node
      # demand throughout the year.
      #
      # Returns a Merit::Curve.
      def demand_profile
        @context.curves.curve(@config.profile, @node)
      end

      # Internal: Fetches demand from the node.
      def node_demand
        if @node.demand.nil? && @node.query.number_of_units.zero?
          # Demand may be nil if it is set by Fever, and the producer has no
          # installed units (therefore was omitted from the calculation).
          0.0
        else
          @node.demand
        end
      end

      # Internal: The full load hours of the participant.
      #
      # Returns a numeric.
      def full_load_hours
        @node.node_api.full_load_hours
      end
    end
  end
end
