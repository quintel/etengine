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
    end
  end
end
