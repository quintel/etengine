# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Converts a Qernel::Converter to a Merit participant and back again.
    class Adapter
      attr_reader :converter, :config

      def self.adapter_for(converter, context)
        klass =
          case context.node_config(converter).type.to_sym
          when :producer
            ProducerAdapter.factory(converter, context)
          when :flex
            FlexAdapter.factory(converter, context)
          when :consumer
            ConsumerAdapter.factory(converter, context)
          else
            self
          end

        klass.new(converter, context)
      end

      def initialize(converter, context)
        @converter = converter.converter_api
        @context   = context
        @config    = context.node_config(converter)
      end

      def participant
        @participant ||= producer_class.new(producer_attributes)
      end

      def inject!
        raise NotImplementedError
      end

      # Internal: Determines whether the participant has any capacity; if not,
      # the participant will not actually be added to the merit order, speeding
      # up calculation times.
      #
      # Returns true or false.
      def installed?
        source_api.number_of_units.positive? &&
          source_api.availability.positive?
      end

      private

      # Internal: Given a Merit order participant +type+ and the associated
      # Converter, +conv+, from the graph, returns a hash of attributes required
      # to set up the Participant object in the Merit order.
      #
      # Returns a hash.
      def producer_attributes
        {
          key: @converter.key,
          number_of_units: source_api.number_of_units,
          availability: source_api.availability,

          # The marginal costs attribute is not optional, but it is an
          # unnecessary calculation when the Merit order is not being run.
          marginal_costs: 0.0
        }
      end

      def producer_class
        raise NotImplementedError
      end

      # Internal: The ConverterApi from which data is taken to be used by the
      # Merit participant.
      #
      # Returns a Qernel::ConverterApi.
      def target_api
        @converter
      end

      # Internal: The ConverterApi on which the results of the Merit calcualtion
      # for the node are stored.
      #
      # Returns a Qernel::ConverterApi.
      def source_api
        @source_api ||=
          if @config.delegate.present?
            @context.graph.converter(@config.delegate).converter_api
          else
            @converter
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
    end
  end
end
