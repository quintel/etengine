# frozen_string_literal: true

module Qernel
  module MeritFacade
    # An always-on battery park is a technology wrapper consisting of two components:
    #
    # * An always-on producer.
    # * A battery for storing excess.
    #
    # The production of the technology is limited by the capacity of a connector to the electricity
    # network. In all hours it will try to output the full capacity of that connection, but when the
    # producer creates more than the capacity of the connection, it will store excess in the
    # battery.
    #
    # Whenever the producer outputs less than the capacity, the battery will be discharged. Excess
    # electricity that cannot be stored in the battery is curtailed.
    #
    #         +------------------------------+
    #         |                              v
    #    +----------+    +---------+    +--------+
    #    | Producer | -> | Battery | -> | Output | -> ...
    #    +----------+    +---------+    +--------+
    #         |
    #         |        +-------------+
    #         +------> | Curtailment |
    #                  +-------------+
    #
    class AlwaysOnBatteryPark
      attr_reader :production_curve, :storage

      def initialize(production_curve:, output_capacity:, storage:)
        @production_curve = production_curve
        @output_capacity = output_capacity
        @storage = storage
      end

      # Curves
      # ------

      def output_curve
        calculate
        storage_out = storage_output_curve
        producer_output_curve.map.with_index { |val, frame| val + storage_out[frame] }
      end

      def producer_output_curve
        @producer_output_curve ||= @production_curve.map { |val| [val, @output_capacity].min }
      end

      # Curtailment
      # -----------

      def curtailment_curve
        calculate
        @curtailment_curve
      end

      # Storage curves
      # --------------

      def storage_input_curve
        calculate
        @storage.load_curve.map { |v| v.negative? ? v.abs : 0.0 }
      end

      def storage_output_curve
        calculate
        @storage.load_curve.map { |v| v.positive? ? v : 0.0 }
      end

      def storage_curve
        calculate
        @storage.reserve.to_a
      end

      private

      def calculate
        return if @calculated

        @curtailment_curve = Array.new(@production_curve.length) { 0.0 }

        @production_curve.each.with_index do |production, frame|
          output = producer_output_curve[frame]

          if output == @output_capacity
            # Surplus or exactly matched demand.
            surplus = production - @output_capacity
            stored  = @storage.assign_excess(frame, surplus)

            # Any unstored surplus is curtailed.
            @curtailment_curve[frame] = surplus - stored
          elsif production < @output_capacity
            # Deficit
            @storage.set_load(
              frame,
              [
                @output_capacity - output,   # Deficit
                @storage.max_load_at(frame)  # Available in storage
              ].min
            )
          end
        end

        # Ensure all storage loads are populated.
        @storage.reserve.at(@production_curve.length - 1)

        @calculated = true

        nil
      end
    end
  end
end
