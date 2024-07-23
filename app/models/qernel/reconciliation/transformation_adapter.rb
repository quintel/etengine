# frozen_string_literal: true

module Qernel
  module Reconciliation
    # Can act both as a producer and consumer when there is in or output demand
    class TransformationAdapter < Adapter
      def inject!(_calculator)
        @node.dataset_lazy_set(@context.curve_name(:output)) do
          demand_curve_output.to_a
        end
        @node.dataset_lazy_set(@context.curve_name(:input)) do
          demand_curve_input.to_a
        end
      end

      def setup(phase:)
        if phase == demand_phase
          @carrier_demand_input = calculate_carrier_demand_input
          @carrier_demand_output = calculate_carrier_demand_output
        end
      end

      def carrier_demand_input
        @carrier_demand_input || raise("carrier_demand_input not yet calulated for #{@node.key}")
      end

      def carrier_demand_output
        @carrier_demand_output || raise("carrier_demand_output not yet calulated for #{@node.key}")
      end

      # TODO: make sure one of them is indeed negative!
      def demand_curve
        Merit::CurveTools.add_curves(demand_curve_input, demand_curve_output)
      end

      def demand_curve_input
        @demand_curve_input ||=
          if carrier_demand_input.zero?
            Merit::Curve.new([0.0] * 8760)
          else
            demand_profile * carrier_demand_input
          end
      end

      def demand_curve_output
        @demand_curve_output ||=
          if carrier_demand_output.zero?
            Merit::Curve.new([0.0] * 8760)
          else
            demand_profile * carrier_demand_output
          end
      end

      private

      def calculate_carrier_demand_output
        # We can't use output_of(carrier) as the graph may not be calculated at
        # the time this method is called.
        node_demand * output_slot.conversion
      end

      def calculate_carrier_demand_input
        # We can't use input_of(carrier) as the graph may not be calculated at
        # the time this method is called.
        node_demand * input_slot.conversion
      end

      def input_slot
        carrier = @config.demand_carrier || @context.carrier

        @node.input(carrier) ||
          raise(<<~ERROR.squish)
            Expected a #{carrier} output on #{@node.key}, but none was
            found.
          ERROR
      end

      def output_slot
        carrier = @config.demand_carrier || @context.carrier

        @node.output(carrier) ||
          raise(<<~ERROR.squish)
            Expected a #{carrier} output on #{@node.key}, but none was
            found.
          ERROR
      end
    end
  end
end
