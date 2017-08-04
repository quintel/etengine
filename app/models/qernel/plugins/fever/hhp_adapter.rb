module Qernel::Plugins
  module Fever
    # An adapter which sets up a hybrid heat-pump to participate in Fever.
    class HHPAdapter < ProducerAdapter
      def inject!
        orig_sec_share = secondary_share

        # Sets the load-adjusted efficiency of the primary component carriers.
        primary_adapter.inject!

        # Set the demands and other attributes based on the whole producer and
        # not the individual parts.
        super

        # Set the conversion of the secondary component carrier.
        sec_demand   = secondary_component.load_curve.sum
        total_demand = primary_component.load_curve.sum + sec_demand
        sec_share    = sec_demand / total_demand

        @converter.converter.input(:network_gas)[:conversion] = sec_share

        # The electric adapter has already set the electricity and ambient heat
        # conversions, but failed to account for the new secondary share.
        balance_primary_efficiency!(orig_sec_share - sec_share)
      end

      def producer
        ::Fever::CompositeProducer.new([primary_component, secondary_component])
      end

      private

      # Internal: The Fever producer which will be the first one asked to
      # satisfy demand.
      def primary_component
        @primary_component ||= primary_adapter.participant.producer
      end

      # Internal: The Fever producer which will be used when the primary
      # producer cannot meet demand.
      def secondary_component
        @secondary_component ||= ::Fever::Producer.new(
          total_value(:heat_output_capacity) * secondary_share
        )
      end

      # Internal: The primary producer is typically a variable-efficiency heat
      # pump.
      def primary_adapter
        @primary_adapter ||= VariableEfficiencyProducerAdapter.new(
          @converter.converter, @graph, @dataset
        )
      end

      # Internal: The share of the secondary component carrier.
      def secondary_share
        1.0-@converter.converter.input(:network_gas).conversion
      end

      # Internal: Re-balances the efficiency of the (typically) electricity and
      # ambient heat inputs to account for how much energy they actually
      # provided relative to the gas component.
      def balance_primary_efficiency!(secondary_delta)
        slots = [
          primary_adapter.based_on_slot,
          primary_adapter.balanced_with_slot
        ]

        total_conv = slots.sum(&:conversion)

        slots.each do |slot|
          slot[:conversion] += secondary_delta * (slot.conversion / total_conv)
        end
      end
    end
  end
end
