# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A global buffer for heat, used in the heat network order.
    #
    # Heat storage typically has infinite input capacity, storing all excesses, but limited output
    # capacity. This means that we have to calculate the demand and full load hours of the node
    # differently. Other flexibility options are calculated using their input capacity; this is not
    # possible with infinite input capacity, so the FLH is calculated based on the output of the
    # participant.
    class HeatStorageAdapter < StorageAdapter
      def inject!
        super

        inject_infinite! if infinite_storage?

        # If the capacity is set dynamically by this adapter, reflect the change on the source node.
        inject_dynamic_output_capacity! if @config.output_capacity_from_demand_of
      end

      def producer_attributes
        attrs = super

        # This must be performed AFTER setting the input capacity per unit (in
        # StorageAdapter#producer_attributes) as this feature specifies that it affects output
        # capacity only.
        if @config.output_capacity_from_demand_of
          attrs[:output_capacity_per_unit] = capacity_from_other_demand
        end

        attrs
      end

      private

      # Infinite storage has an infinitely large reserve, which is then resized after the
      # calculation to be the maximum value stored.
      def infinite_storage?
        @config.group == :infinite
      end

      # Internal: Sets demand and related attributes on the target API. Determines demand using the
      # output (since input capacity may be infinite) rather than the input as is the case for other
      # flexibility technologies.
      def inject_demand!
        target_api.demand = participant.production / output_efficiency

        full_load_hours =
          target_api.demand / (
            participant.output_capacity_per_unit *
            participant.number_of_units *
            3600
          )

        target_api[:full_load_hours]   = full_load_hours
        target_api[:full_load_seconds] = full_load_hours * 3600
      end

      def inject_infinite!
        reserve = @participant.reserve
        stored = Array.new(8760) { |frame| reserve.at(frame) }

        source_api.storage.volume = stored.max.ceil.to_f

        inject_curve!(full_name: :storage_curve) { stored }
      end

      def storage_volume_per_unit
        infinite_storage? ? Float::INFINITY : super
      end

      # Heat storage should not overwrite fuel costs
      def inject_fuel_costs!;end
    end
  end
end
