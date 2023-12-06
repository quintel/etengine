# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Load shifting adds two participants to the merit order. A flexible participant steps in
    # whenever the price reaches a threshold, and an inflexible participant will ensure that the
    # load output by the flexible part is always recovered by the end of the year. Load shifting
    # is energy neutral: energy out = energy in.
    class LoadShiftingAdapter < FlexAdapter
      def participant
        @participant ||= Merit::Flex::LoadShifting.build(producer_attributes)
      end

      def inject!
        flh = full_load_hours

        target_api[:full_load_hours]   = flh
        target_api[:full_load_seconds] = flh * 3600

        target_api.demand =
          main_participant.output_capacity_per_unit *
          main_participant.number_of_units *
          target_api.full_load_seconds

        # TODO: Set input and output capacities.
        target_api.typical_input_capacity = input_capacity
        target_api.electricity_output_capacity = output_capacity

        inject_curve!(:input) do
          main_participant.load_curve.map { |v| v.negative? ? v.abs : 0.0 }
        end

        inject_curve!(:output) do
          main_participant.load_curve.map { |v| v.positive? ? v : 0.0 }
        end
      end

      private

      def main_participant
        participant.first
      end

      def producer_attributes
        attrs = super
        attrs[:limiting_curve] = limiting_curve

        if @config.load_shifting_hours
          attrs[:deficit_capacity] =
            attrs[:output_capacity_per_unit] *
            attrs[:number_of_units] *
            target_api.availability *
            @config.load_shifting_hours
        end

        attrs
      end

      def input_efficiency
        1.0
      end

      def output_efficiency
        1.0
      end

      # Limits the amount of energy the participant may output in each hour. This is based on the
      # demand of the downstream participants. The curve is limited by the availability of the node.
      def limiting_curve
        @limiting_curve ||= begin
          parts = downstream_participants

          if parts.empty?
            [0.0] * Merit::POINTS
          else
            Merit::CurveTools.add_curves(downstream_participants.map(&:load_curve))
          end
        end
      end

      def input_capacity
        @input_capacity = (@config.input_capacity_from_share || 0.0) * output_capacity
      end

      def output_capacity
        # The input capacity will be further affected in Merit by the availability of the node.
        @output_capacity ||= limiting_curve.max
      end

      # Finds all the participants for the nodes named in the `demand_sources` config attribute.
      #
      # This allows us to extract their load curves, which are in turn used to limit the demand of
      # the load-shifting participant.
      #
      # There are no checks performed that nodes exist, nor that they are users. Instead this is
      # validated by Atlas in the ETSource specs.
      def downstream_participants
        Array(@config.demand_source)
          .map { |key| @context.plugin.adapters[key.to_sym] }
          .select(&:installed?)
          .flat_map(&:participant)
      end

      # Calculates the full load hours of the load shifting based on the amount of energy produced.
      def full_load_hours
        return 0.0 if source_api.number_of_units.zero?

        production = main_participant.load_curve.sum { |v| v.positive? ? v : 0.0 }

        return 0.0 if production.zero?

        production / (input_capacity * source_api.number_of_units)
      end
    end
  end
end
