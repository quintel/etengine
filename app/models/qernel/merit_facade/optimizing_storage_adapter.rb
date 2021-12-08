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
        Params.new(
          input_capacity:    source_api.input_capacity,
          output_capacity:   @context.carrier_named('%s_output_capacity'),
          volume:            source_api.storage.volume * source_api.number_of_units,
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
          target_api.number_of_units

        inject_curve!(full_name: :storage_curve) do
          @context.storage_optimization.reserve_for(source_api.key)
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
        @production_participant ||= Merit::CurveProducer.new(
          key: :"#{@node.key}_producer",
          marginal_costs: :null,
          load_curve: @context.storage_optimization.load_for(source_api.key).map do |v|
            v.positive? ? v : 0.0
          end
        )
      end

      def consumption_participant
        @consumption_participant ||= Merit::User.create(
          key: :"#{@node.key}_consumer",
          load_curve: @context.storage_optimization.load_for(source_api.key).map do |v|
            v.negative? ? v.abs : 0.0
          end
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

      def output_capacity_per_unit
        source_api.public_send(@context.carrier_named('%s_output_conversion')) *
          source_api.input_capacity
      end

      def output_efficiency
        conversion = @context.carrier_named('%s_output_conversion')
        converstion.zero? ? 0.0 : 1.0 / conversion
      end

      def producer_class
        Merit::CurveProducer
      end
    end
  end
end
