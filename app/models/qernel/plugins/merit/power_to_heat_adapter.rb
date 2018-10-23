module Qernel::Plugins
  module Merit
    class PowerToHeatAdapter < StorageAdapter
      def inject!
        super

        full_load_hours =
          participant.production * output_efficiency / (
            participant.input_capacity_per_unit *
            participant.number_of_units *
            3600
          )

        if ! full_load_hours || full_load_hours.nan?
          full_load_seconds = full_load_hours = 0.0
        else
          full_load_seconds = full_load_hours * 3600
        end

        target_api[:full_load_hours]   = full_load_hours
        target_api[:full_load_seconds] = full_load_seconds

        target_api.demand =
          full_load_seconds *
          source_api.input_capacity *
          participant.number_of_units
      end

      private

      def producer_attributes
        attrs = super

        attrs[:excess_share] = excess_share
        attrs[:group] = @config.group

        if source_api.number_of_units.positive?
          # Swap back to the slower Reserve which supports decay.
          attrs[:reserve_class] = ::Merit::Flex::Reserve
          attrs[:decay] = reserve_decay
        end

        # Do not emit anything; it has been converted to hot water.
        attrs[:output_capacity_per_unit] = 0.0

        attrs
      end

      def reserve_decay
        # Remove from the storage ("buffer") as much as possible to satisfy
        # the demand profile.
        decay = subtraction_profile
        ->(point, _) { decay.get(point) }
      end

      def subtraction_profile
        demand_profile *
          @graph.converter(@config.demand_source).converter_api.demand
      end

      def demand_profile
        @dataset.load_profile(@config.demand_profile)
      end

      # Internal: Participants belonging to a group with others should receive
      # a share of excess proportional to their capacity.
      #
      # Returns a numeric.
      def excess_share
        self_cap = source_api.input_capacity * source_api.number_of_units
        group_cap = 0.0

        return 0.0 if self_cap.zero?

        # Find all flex converters belonging to the same group.
        @graph.plugin(:merit).each_adapter do |adapter|
          aconf = adapter.config
          conv = adapter.converter

          next if aconf.group != @config.group || aconf.type != @config.type

          group_cap += conv.input_capacity * conv.number_of_units
        end

        return 1.0 if group_cap.zero?

        self_cap / group_cap
      end
    end # PowerToHeatAdapter
  end # Merit
end
