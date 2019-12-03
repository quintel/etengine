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

        # If the output slot has two links, one a share link and one inversed
        # flexible, assume that unused energy is dumped through the flexible.
        # Adjust the share edge so that only energy actually emitted by the
        # storage flows.
        output_slot = @converter.converter.output(@context.carrier)

        return if !output_slot || output_slot.links.length != 2

        share_link = output_slot.links.detect(&:share?)
        if_link = output_slot.links.detect(&:inversed_flexible?)

        return unless share_link && if_link

        total = target_api.demand * output_slot.conversion / 3600

        new_share =
          if total.zero?
            0.0
          else
            @participant.load_curve.sum { |v| v.positive? ? v : 0.0 } / total
          end

        share_link.dataset_set(:share, new_share)
      end

      private

      def producer_attributes
        attrs = super

        attrs[:reserve_class] = Merit::Flex::SimpleReserve

        attrs[:input_capacity_per_unit] =
          source_api.input_capacity ||
          source_api.output_capacity

        attrs[:volume_per_unit] = storage_volume_per_unit

        attrs[:input_efficiency]  = input_efficiency
        attrs[:output_efficiency] = output_efficiency

        attrs
      end

      def storage_volume_per_unit
        source_api.dataset_get(:storage).volume *
          (1 - (source_api.reserved_fraction || 0.0))
      end

      def producer_class
        Merit::Flex::Storage
      end

      def input_efficiency
        slots = @converter.converter.inputs.reject(&:loss?)
        1 / (slots.any? ? slots.sum(&:conversion) : 1.0)
      end
    end
  end
end
