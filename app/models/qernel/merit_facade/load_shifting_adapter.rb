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

      # Inject adjusted input and output curves into the Merit order, enforcing a cumulative deficit cap
      def inject!
        max_deficit  = producer_attributes[:deficit_capacity] || Float::INFINITY
        full_hours   = full_load_hours

        target_api[:full_load_hours]    = full_hours
        target_api[:full_load_seconds]  = full_hours * 3600
        target_api.demand               = (
          main_participant.output_capacity_per_unit *
          main_participant.number_of_units *
          target_api.full_load_seconds
        )
        target_api.typical_input_capacity     = input_capacity
        target_api.electricity_output_capacity = output_capacity

        raw_curve     = main_participant.load_curve
        input_curve, output_curve = apply_deficit_limit(raw_curve, max_deficit)

        inject_curve!(:input)  { input_curve }
        inject_curve!(:output) { output_curve }
      end

      private

      # Applies the cumulative deficit limit to the raw load curve.
      # Returns two arrays: [input_curve, output_curve].
      def apply_deficit_limit(raw_curve, max_deficit)
        cumulative_deficit = 0.0
        input_curve, output_curve = [], []

        raw_curve.each do |value|
          input_value, output_value, cumulative_deficit =
            process_value(value, cumulative_deficit, max_deficit)

          input_curve  << input_value
          output_curve << output_value
        end

        [input_curve, output_curve]
      end

      # Process a single time step value with cumulative deficit tracking
      def process_value(value, cumulative_deficit, max_deficit)
        if value.positive?
          shifted_out = shift_out(value, cumulative_deficit, max_deficit)
          cumulative_deficit += shifted_out
          [0.0, shifted_out, cumulative_deficit]
        elsif value.negative?
          recovery = recover(-value, cumulative_deficit)
          cumulative_deficit -= recovery
          [recovery, 0.0, cumulative_deficit]
        else
          [0.0, 0.0, cumulative_deficit]
        end
      end

      # Determine how much can be shifted out given remaining deficit capacity
      def shift_out(value, cumulative_deficit, max_deficit)
        return 0.0 if cumulative_deficit >= max_deficit
        [value, max_deficit - cumulative_deficit].min
      end

      # Determine how much deficit can be recovered
      def recover(amount, cumulative_deficit)
        [cumulative_deficit, amount].min
      end

      def main_participant
        participant.first
      end

      # Build the hash of attributes for the Merit participant, including deficit_capacity
      def producer_attributes
        base_attrs = super
        base_attrs[:limiting_curve] = limiting_curve

        # Determine cumulative deficit capacity: hours>0 applies cap, else unlimited
        hours = (target_api[:load_shifting_hours] || @config.load_shifting_hours).to_f
        base_attrs[:deficit_capacity] =
          if hours.positive?
            base_attrs[:output_capacity_per_unit] *
            base_attrs[:number_of_units] *
            target_api.availability *
            hours
          else
            Float::INFINITY
          end

        base_attrs
      end

      # These methods define efficiencies but are not used directly here.
      def input_efficiency;  1.0; end
      def output_efficiency; 1.0; end

      # Limits the amount of energy the participant may output in each hour. This is based on the
      # demand of the downstream participants. The curve is limited by the availability of the node.
      def limiting_curve
        @limiting_curve ||= begin
          parts = downstream_participants
          if parts.empty?
            [0.0] * Merit::POINTS
          else
            Merit::CurveTools.add_curves(parts.map(&:load_curve))
          end
        end
      end

      # Input capacity is a share of output capacity
      def input_capacity
        (@config.input_capacity_from_share || 0.0) * output_capacity
      end

      # Output capacity is determined by the peak of the limiting_curve
      def output_capacity
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
        units = source_api.number_of_units
        return 0.0 if units.zero?

        total_output = main_participant.load_curve.sum { |v| v.positive? ? v : 0.0 }
        return 0.0 if total_output.zero?

        total_output / (input_capacity * units)
      end
    end
  end
end
