# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sets up generic power-to-heat participants in Merit.
    class PowerToHeatAdapter < StorageAdapter
      def initialize(*)
        super
        @heat_output_curve = Array.new(8760, 0.0)
      end

      def inject!
        super

        production = participant.production

        full_load_hours =
          production / input_efficiency / (
            source_api.input_capacity *
            participant.number_of_units *
            3600
          )

        full_load_seconds =
          if !full_load_hours || full_load_hours.nan?
            full_load_hours = 0.0
          else
            full_load_hours * 3600
          end

        target_api[:full_load_hours]   = full_load_hours
        target_api[:full_load_seconds] = full_load_seconds

        target_api.demand = production

        inject_curve!(full_name: :heat_output_curve) { @heat_output_curve }
      end

      private

      def producer_attributes
        attrs = super

        attrs[:excess_share] = excess_share
        attrs[:group] = @config.group

        if source_api.number_of_units.positive?
          # Swap back to the slower Reserve which supports decay.
          attrs[:reserve_class] = Merit::Flex::Reserve
          attrs[:decay] = reserve_decay
        end

        # Adjustment for https://github.com/quintel/etengine/issues/1118, due to
        # the inability to set the buffer volume to 0 (to prevent spiking loads
        # when empty).
        if source_api.number_of_units.positive?
          attrs[:input_capacity_per_unit] = [
            attrs[:input_capacity_per_unit],
            total_demand / 3600 / 8760 / # Slash highlighting
              source_api.number_of_units / # / Slash highlighting
              @node.node.output(:useable_heat).conversion
          ].min
        end

        # Do not emit anything; it has been converted to hot water.
        attrs[:output_capacity_per_unit] = 0.0

        attrs
      end

      def reserve_decay
        # Remove from the storage ("buffer") as much as possible to satisfy
        # the demand profile.
        decay = subtraction_profile
        conversion = @node.node.output(:useable_heat).conversion

        lambda do |point, stored|
          wanted = decay.get(point) / conversion
          heat = (stored > wanted ? wanted : stored) * conversion

          @heat_output_curve[point] = heat

          decay.get(wanted)
        end
      end

      def subtraction_profile
        demand_profile * total_demand
      end

      def demand_profile
        @context.curves.curve(@config.demand_profile, source_api)
      end

      def total_demand
        @context.graph.node(@config.demand_source).node_api.demand
      end

      # Internal: Participants belonging to a group with others should receive
      # a share of excess proportional to their capacity.
      #
      # Returns a numeric.
      def excess_share
        self_cap = source_api.input_capacity * source_api.number_of_units
        group_cap = 0.0

        return 0.0 if self_cap.zero?

        # Find all flex nodes belonging to the same group.
        @context.plugin.each_adapter do |adapter|
          aconf = adapter.config
          conv = adapter.node

          next if aconf.group != @config.group || aconf.type != @config.type

          group_cap += conv.input_capacity * conv.number_of_units
        end

        return 1.0 if group_cap.zero?

        self_cap / group_cap
      end
    end
  end
end
