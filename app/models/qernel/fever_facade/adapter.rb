# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Base class which handles setting up the participant in Fever, and
    # converting data post-calculation to be added back to ETEngine.
    class Adapter
      attr_reader :node

      def self.adapter_for(node, context)
        type = node.dataset_get(:fever).type.to_sym

        klass =
          case type
          when :producer then ProducerAdapter.factory(node, context)
          when :storage  then StorageAdapter
          when :consumer then ConsumerAdapter
          else raise "Unknown Fever type: #{type}"
          end

        klass.new(node, context)
      end

      def initialize(node, context)
        @node = node.node_api
        @context   = context
        @config    = node.dataset_get(:fever)

        # Store this now; technologies with a flexible edge will not have the
        # share set when running inject! which results in the number_of_units
        # being incorrectly set to 0.
        number_of_units
      end

      def inspect
        "#<#{self.class.name} node=#{@node.key}>"
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
        per_unit = block_given? ? yield : @node.public_send(attribute)
        per_unit * @number_of_units
      end

      def number_of_units
        @number_of_units ||= @node.number_of_units
      end

      # Internal: Assigns a computed curve to the node API. Provide a
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

        name = full_name || :"heat_#{direction}_curve"

        @node.dataset_lazy_set(name.to_sym) do
          @context.curves.derotate(yield.to_a)
        end
      end
    end
  end
end
