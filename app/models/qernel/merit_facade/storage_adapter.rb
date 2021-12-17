# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sets up storage in Merit; typically used for household batteries or
    # storage in electric vehicles.
    class StorageAdapter < FlexAdapter
      def installed?
        # Skip storage when there is no volume for storing energy.
        super && storage_volume_per_unit.positive?
      end

      def inject!
        super
        inject_dumped_energy_attributes!
        inject_storage_curve!
      end

      private

      def producer_attributes
        attrs = super

        attrs[:consumption_price] = source_api.max_consumption_price

        attrs[:input_efficiency]  = input_efficiency
        attrs[:output_efficiency] = output_efficiency

        attrs.merge!(storage_attributes)

        attrs
      end

      def storage_attributes
        attrs = { volume_per_unit: storage_volume_per_unit }

        decay_factor = source_api.storage.decay

        if decay_factor&.positive?
          attrs[:decay] = ->(_, amount) { amount * decay_factor }
        end

        # Random access to the reserve's `add` and `take` methods aren't
        # required, so we may use the faster reserve.
        attrs[:reserve_class] = Merit::Flex::SimpleReserve

        attrs
      end

      def storage_volume_per_unit
        source_api.storage.volume
      end

      def producer_class
        Merit::Flex::Storage
      end

      # Internal: Storage with two outputs uses one of the outputs to dump unused energy from the
      # reserve.
      #
      # Energy emitted by the reserve to be used passes through the share edge, while all remaining
      # unused energy is dumped throught he inversed_flexible.
      def inject_dumped_energy_attributes!
        # If the output slot has two edges, one a share edge and one inversed
        # flexible, assume that unused energy is dumped through the flexible.
        # Adjust the share edge so that only energy actually emitted by the
        # storage flows.
        output_slot = @node.node.output(@context.carrier)

        return if !output_slot || output_slot.edges.length != 2

        share_edge = output_slot.edges.detect(&:share?)
        if_edge = output_slot.edges.detect(&:inversed_flexible?)

        return unless share_edge && if_edge

        total = target_api.demand * output_slot.conversion / 3600

        new_share =
          if total.zero?
            0.0
          else
            @participant.load_curve.sum { |v| v.positive? ? v : 0.0 } / total
          end

        share_edge.dataset_set(:share, new_share)
      end

      def inject_infinite!
        source_api.storage.volume = @participant.reserve.to_a.max.ceil.to_f
      end

      def inject_dynamic_output_capacity!
        capacity = @participant.output_capacity_per_unit
        target_api.output_capacity = capacity

        if @context.carrier == :electricity
          target_api.electricity_output_capacity = capacity
        elsif @context.carrier == :steam_hot_water
          target_api.heat_output_capacity = capacity
        end
      end

      def inject_storage_curve!
        @participant.reserve.at(8759) # Ensure any trailing values are set to zero.
        inject_curve!(full_name: :storage_curve) { @participant.reserve.to_a }
      end

      # Internal: When "output_capacity_from_demand_of" is set, set the capacity
      # of the storage to be equal to the average demand of another node,
      # multiplied by a constant chosen by the user.
      def capacity_from_other_demand
        node = @context.graph.node(@config.output_capacity_from_demand_of)
        avg_load = node.demand / 8760 / 3600

        avg_load * @config.output_capacity_from_demand_share
      end
    end
  end
end
