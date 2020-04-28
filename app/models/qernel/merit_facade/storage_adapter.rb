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

        inject_infinite! if infinite_storage?

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

        attrs[:input_capacity_per_unit] =
          source_api.input_capacity ||
          source_api.output_capacity

        attrs[:input_efficiency]  = input_efficiency
        attrs[:output_efficiency] = output_efficiency

        attrs.merge!(storage_attributes)
      end

      def storage_attributes
        attrs = { volume_per_unit: storage_volume_per_unit }

        decay_factor = source_api.storage.decay

        if decay_factor&.positive?
          attrs[:decay] = ->(_, amount) { amount * decay_factor }
        end

        unless @context.carrier == :steam_hot_water
          # Heat network storage requires the ability to fetch the full storage
          # curve; not supported by SimpleReserve.
          attrs[:reserve_class] = Merit::Flex::SimpleReserve
        end

        attrs
      end

      def storage_volume_per_unit
        infinite_storage? ? Float::INFINITY : source_api.storage.volume
      end

      def producer_class
        Merit::Flex::Storage
      end

      # Infinite storage has an infinitely large reserve, which is then resized
      # after the calculation to be the maximum value stored.
      def infinite_storage?
        @config.group == :infinite
      end

      def inject_infinite!
        reserve = @participant.reserve
        stored = Array.new(8760) { |frame| reserve.at(frame) }

        source_api.storage.volume = stored.max.ceil.to_f

        inject_curve!(full_name: :storage_curve) { stored }
      end
    end
  end
end
