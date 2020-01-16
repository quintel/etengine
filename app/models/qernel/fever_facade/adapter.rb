# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Base class which handles setting up the participant in Fever, and
    # converting data post-calculation to be added back to ETEngine.
    class Adapter
      attr_reader :converter

      def self.adapter_for(converter, context)
        type = converter.dataset_get(:fever).type.to_sym

        klass =
          case type
          when :producer then ProducerAdapter.factory(converter, context)
          when :storage  then StorageAdapter
          when :consumer then ConsumerAdapter
          else raise "Unknown Fever type: #{type}"
          end

        klass.new(converter, context)
      end

      def initialize(converter, context)
        @converter = converter.converter_api
        @context   = context
        @config    = converter.dataset_get(:fever)

        # Store this now; technologies with a flexible edge will not have the
        # share set when running inject! which results in the number_of_units
        # being incorrectly set to 0.
        number_of_units
      end

      def inspect
        "#<#{self.class.name} converter=#{@converter.key}>"
      end

      def participant
        raise NotImplementedError
      end

      def inject!
        raise NotImplementedError
      end

      def producer_for_carrier(_carrier)
        raise NotImplementedError
      end

      # If the adapter has a producer whose demand should be included as part of
      # the main fever demand curve, returns the producer.
      def producer_for_electricity_demand
        producer_for_carrier(:electricity)
      end

      private

      # Internal: Fever expects totals -- not per-unit -- values. Using this
      # method will ensure you always get a total value.
      #
      # Returns a numeric.
      def total_value(attribute = nil)
        per_unit = block_given? ? yield : @converter.public_send(attribute)
        per_unit * @number_of_units
      end

      def number_of_units
        @number_of_units ||= @converter.number_of_units
      end
    end
  end
end
