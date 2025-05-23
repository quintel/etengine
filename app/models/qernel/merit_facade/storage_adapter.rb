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

      def marginal_costs
        # Read cost from the target API, since its cost may differ from that set on the source.
        @context.dispatchable_sorter.cost(target_api, @config)
      end

      def producer_attributes
        attrs = super

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
      # Energy emitted by the reserve to be used passes through the carier slot, while all remaining
      # unused energy is dumped through the loss.
      def inject_dumped_energy_attributes!
        # If the node has two output slots, one with the carrier and one as a loss,
        # assume that unused energy is dumped through the loss.
        # Adjust the shares so that only energy actually emitted by the
        # storage flows.
        output_slot = @node.node.output(@context.carrier)
        loss_slot = @node.node.output(:loss)

        return if !output_slot || !loss_slot

        total = target_api.demand * output_slot.conversion / 3600

        new_share =
          if total.zero?
            0.0
          else
            @participant.load_curve.sum { |v| v.positive? ? v : 0.0 } / total
          end

        output_slot[:conversion] = new_share
        loss_slot[:conversion] = 1.0 - new_share
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

      def inject_costs!
        super

        target_api.dataset_lazy_set(:revenue_hourly_electricity) do
          participant.revenue
        end

        target_api.dataset_lazy_set(:revenue_hourly_electricity_per_mwh) do
          participant.revenue_per_mwh
        end
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
