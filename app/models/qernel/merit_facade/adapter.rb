# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Converts a Qernel::Node to a Merit participant and back again.
    class Adapter
      attr_reader :node, :config

      def self.adapter_for(node, context)
        klass =
          case context.node_config(node).type.to_sym
          when :producer
            ProducerAdapter.factory(node, context)
          when :flex
            FlexAdapter.factory(node, context)
          when :consumer
            ConsumerAdapter.factory(node, context)
          else
            self
          end

        klass.new(node, context)
      end

      def initialize(node, context)
        @node = node.node_api
        @context = context
        @config = context.node_config(node)
      end

      def participant
        @participant ||= producer_class.new(producer_attributes)
      end

      def inject!
        raise NotImplementedError
      end

      # Public: Sets the installed input and output capacity of the participant on the node if
      # calcuable, as `<carrier>_<direction>_installed_capacity`. Not used in calculation.
      #
      # CHECK THIS: "Must be called before #inject!, which may change the attributes the capacity is based on
      # (such as conversions).""
      def inject_installed_capacity!
        target_api.dataset_set(
          :"#{@context.carrier}_input_installed_capacity",
          installed_input_capacity
        )
        target_api.dataset_set(
          :"#{@context.carrier}_output_installed_capacity",
          installed_output_capacity
        )
      end

      # Internal: Determines whether the participant has any capacity; if not,
      # the participant will not actually be added to the merit order, speeding
      # up calculation times.
      #
      # Returns true or false.
      def installed?
        source_api.number_of_units.positive? && positive_availability?
      end

      private

      # Internal: The installed input capacity of the participant.
      def installed_input_capacity
        nil
      end

      # Internal: The installed output capacity of the participant.
      def installed_output_capacity
        nil
      end

      # Internal: The peak load of the participant in the given direction.
      # Merit load curves are negative for consumption and positive for production.
      def peak_load(direction)
        curve = participant.load_curve.to_a
        direction == :input ? -[curve.min, 0.0].min : [curve.max, 0.0].max
      end

      # Internal: Given a Merit order participant +type+ and the associated
      # Node, +node+, from the graph, returns a hash of attributes required
      # to set up the Participant object in the Merit order.
      #
      # Returns a hash.
      def producer_attributes
        {
          key: @node.key,
          number_of_units: source_api.number_of_units,
          availability: target_api.availability,

          # The marginal costs attribute is not optional, but it is an
          # unnecessary calculation when the Merit order is not being run.
          marginal_costs: 0.0
        }
      end

      def producer_class
        raise NotImplementedError
      end

      # Internal: The NodeApi from which data is taken to be used by the
      # Merit participant.
      #
      # Returns a Qernel::NodeApi.
      def target_api
        @node
      end

      # Internal: The NodeApi on which the results of the Merit calcualtion
      # for the node are stored.
      #
      # Returns a Qernel::NodeApi.
      def source_api
        @source_api ||=
          if @config.delegate.present?
            @context.graph.node(@config.delegate).node_api
          else
            @node
          end
      end

      # Internal: Assigns a computed curve to the target API. Provide a
      # direction (input or output) in order to determine the name of the
      # attribute to be set, and a block which yields the calculated curve.
      #
      # `inject_curve!` will take care of derotating the curve as necessary in
      # order that its first point represents January 1st 00:00.
      #
      # For example:
      #
      #   inject_curve!(:output) do
      #     @participant.load_curve
      #   end
      #
      # You may optionally provide a full curve name when you wish to set a
      # curve for a different carrier or attribute. For example:
      #
      #   inject_curve!(full_name: :storage_curve) do
      #     @participant.reserve.to_a
      #   end
      #
      # Returns nothing.
      def inject_curve!(direction = nil, full_name: nil)
        if direction.nil? && full_name.nil?
          raise 'No curve name given to inject_curve!'
        end

        name = full_name || @context.curve_name(direction)

        target_api.dataset_lazy_set(name) do
          @context.curves.derotate(yield.to_a)
        end
      end

      # Internal: Returns if the adapter has non-zero availability.
      def positive_availability?
        target_api.availability.positive?
      end
    end
  end
end
