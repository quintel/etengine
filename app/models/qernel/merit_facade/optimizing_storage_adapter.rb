# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A storage technology whose hourly load is calculated outside of Merit by an algorithm which
    # tries to flatten a residual load curve.
    class OptimizingStorageAdapter < Adapter
      # Contains useful information about the storage technology for the optimization algorithm.
      Params = Struct.new(
        :input_capacity,
        :output_capacity,
        :volume,
        :output_efficiency,
        keyword_init: true
      ) do
        def installed?
          input_capacity.positive? && output_capacity.positive? &&
            volume.positive? && output_efficiency.positive?
        end
      end

      def installed?
        # Skip storage when there is no volume or capacity.
        super && optimizing_storage_params.installed?
      end

      def initialize(*args)
        super

        if (source_api.input(@context.carrier)&.conversion || 1.0) != 1.0
          raise "Optimizing storage only support input conversion of 1.0 (on #{source_api.key})"
        end

        if source_api.storage.decay != 0.0
          raise "Optimizing storage does not support storage decay (on #{source_api.key})"
        end
      end

      def optimizing_storage_params
        multiple = source_api.number_of_units * target_api.availability

        Params.new(
          input_capacity:    source_api.input_capacity * multiple,
          output_capacity:   output_capacity * multiple,
          volume:            source_api.storage.volume * multiple,
          output_efficiency: output_efficiency
        )
      end

      def inject!
        flh = full_load_hours

        target_api[:full_load_hours]   = flh
        target_api[:full_load_seconds] = flh * 3600

        target_api.demand =
          target_api[:full_load_seconds] *
          source_api.input_capacity *
          source_api.number_of_units

        inject_curve!(full_name: :storage_curve) do
          @context.storage_optimization.reserve_for(@node.key)
        end

        inject_curve!(:input) do
          consumption_participant.load_curve
        end

        inject_curve!(:output) do
          production_participant.load_curve
        end

        # TODO: Figure out the battery price based on the electricity price curve.
      end

      def participant
        [production_participant, consumption_participant]
      end

      private

      def production_participant
        @production_participant ||= Merit::Flex::OptimizingStorage::Producer.new(
          key: :"#{@node.key}_producer",
          marginal_costs: :null,
          load_curve: Merit::Curve.new(
            @context.storage_optimization.load_for(@node.key).map do |v|
              v.positive? ? v : 0.0
            end
          )
        )
      end

      def consumption_participant
        @consumption_participant ||= Merit::Flex::OptimizingStorage::Consumer.new(
          key: :"#{@node.key}_consumer",
          load_curve: Merit::Curve.new(
            @context.storage_optimization.load_for(@node.key).map do |v|
              v.negative? ? v.abs : 0.0
            end
          )
        )
      end

      def full_load_hours
        if source_api.input_capacity.zero? || source_api.number_of_units.zero?
          0.0
        else
          production = consumption_participant.load_curve.sum
          production / (source_api.input_capacity * source_api.number_of_units)
        end
      end

      def output_capacity
        cap = total_node_output_capacity || source_api.input_capacity
        cap * output_efficiency
      end

      def total_node_output_capacity
        source_api.try(@context.carrier_named('%s_output_capacity')) || source_api.output_capacity
      end

      def output_efficiency
        target_api.public_send(@context.carrier_named('%s_output_conversion'))
      end

      def producer_class
        Merit::CurveProducer
      end
    end
  end
end
