# frozen_string_literal: true

module Qernel
  module NodeApi
    # Calculates the installed capacity of a node per carrier and direction, for the carriers in the
    # time-resolved calculations: electricity, hydrogen, network gas and steam hot water.
    #
    # The installed capacity is taken from, in order:
    # - The participant in the Merit order (electricity, hydrogen, heat networks, agriculture heat)
    # - Typical input capacity × carrier conversion × number of units (network gas, Merit consumers,
    #   which have no capacity in Merit, and nodes outside the time-resolved calculations)
    # - The peak of the hourly curve, for nodes without a capacity of their own: demand, losses,
    #   backups (sized to their own peak) and unlimited participants (curtailment, heat storage)
    #
    # These methods are only used by the capacity data exports and are not cached, as they are only
    # meaningful after the calculation. The existing capacity methods (Cost#input_capacity,
    # CapacityProduction) are left untouched and are to be merged into this module later.
    module Capacity
      # ETSource uses 1e15 MW for unlimited capacity, e.g. on heat network storage.
      UNLIMITED_CAPACITY = 1e15

      # The participant configs of each carrier in the time-resolved calculations.
      PARTICIPANT_ORDERS = {
        electricity: %i[merit_order],
        hydrogen: %i[hydrogen],
        network_gas: %i[network_gas],
        steam_hot_water: %i[heat_network_lt heat_network_mt heat_network_ht agriculture_heat]
      }.freeze

      # Installed electricity input capacity.
      #
      # @return [Float] Installed capacity in MW
      def electricity_input_installed_capacity
        installed_capacity(:electricity, :input)
      end

      # Installed electricity output capacity.
      #
      # @return [Float] Installed capacity in MW
      def electricity_output_installed_capacity
        installed_capacity(:electricity, :output)
      end

      # Installed hydrogen input capacity.
      #
      # @return [Float] Installed capacity in MW
      def hydrogen_input_installed_capacity
        installed_capacity(:hydrogen, :input)
      end

      # Installed hydrogen output capacity.
      #
      # @return [Float] Installed capacity in MW
      def hydrogen_output_installed_capacity
        installed_capacity(:hydrogen, :output)
      end

      # Installed network gas input capacity.
      #
      # @return [Float] Installed capacity in MW
      def network_gas_input_installed_capacity
        installed_capacity(:network_gas, :input)
      end

      # Installed network gas output capacity.
      #
      # @return [Float] Installed capacity in MW
      def network_gas_output_installed_capacity
        installed_capacity(:network_gas, :output)
      end

      # Installed steam hot water input capacity.
      #
      # @return [Float] Installed capacity in MW
      def steam_hot_water_input_installed_capacity
        installed_capacity(:steam_hot_water, :input)
      end

      # Installed steam hot water output capacity.
      #
      # @return [Float] Installed capacity in MW
      def steam_hot_water_output_installed_capacity
        installed_capacity(:steam_hot_water, :output)
      end

      private

      # Installed capacity of the node, or the peak of its hourly curve when it has no capacity of
      # its own.
      #
      # @return [Float] Installed capacity in MW
      def installed_capacity(carrier, direction)
        own_installed_capacity(carrier, direction) ||
          public_send(:"#{carrier}_#{direction}_curve")&.max ||
          0.0
      end

      # Installed capacity of the node itself.
      #
      # @return [Float, nil] Installed capacity in MW, or nil if the node has no capacity of its own
      def own_installed_capacity(carrier, direction)
        return if backup_participant?

        order = participant_order(carrier)
        config = public_send(order) if order
        adapter = merit_adapter(order) if config && config.type != :consumer

        return participant_capacity(adapter, direction) if adapter

        nameplate_capacity(config.try(:demand_carrier) || carrier, direction)
      end

      # Whether the node is a backup in a Merit order. A backup sets its number of units from its
      # own peak, which applies to all its carriers.
      #
      # @return [Boolean]
      def backup_participant?
        [merit_order, hydrogen, agriculture_heat, heat_network_lt, heat_network_mt, heat_network_ht]
          .any? { |config| config.try(:subtype) == :backup }
      end

      # The participant config of the node in the time-resolved calculation of the carrier.
      #
      # @return [Symbol, nil] Name of the config, or nil if the node does not participate
      def participant_order(carrier)
        PARTICIPANT_ORDERS[carrier].find { |name| public_send(name) }
      end

      # The Merit adapter of the node.
      #
      # @return [Qernel::MeritFacade::Adapter, nil] The adapter, or nil for network gas (which has
      #   no Merit order) and graphs without time-resolved calculations (such as the present graph)
      def merit_adapter(order)
        plugin = node.graph.plugin(:time_resolve)
        return unless plugin

        manager =
          case order
          when :merit_order      then plugin.merit
          when :hydrogen         then plugin.hydrogen
          when :agriculture_heat then plugin.agriculture_heat
          when :heat_network_lt, :heat_network_mt, :heat_network_ht
            plugin.heat_network.manager_for(node)
          end

        manager&.adapters&.[](key)
      end

      # Capacity of the Merit participant.
      #
      # @return [Float, nil] Capacity in MW, or nil if the participant has no or unlimited capacity
      def participant_capacity(adapter, direction)
        # Building a participant which isn't in the order may calculate extra values; skip it.
        return 0.0 unless adapter.installed?

        capacity =
          if adapter.respond_to?(:optimizing_storage_params)
            # Its participants only replay a precalculated curve; the optimizer uses these limits.
            adapter.optimizing_storage_params[:"#{direction}_capacity"]
          else
            # Load shifting has several participants; the first holds the capacity.
            participant = Array.wrap(adapter.participant).first
            per_unit = participant.try(:"#{direction}_capacity_per_unit")
            per_unit && (per_unit * participant.number_of_units)
          end

        return if capacity.nil? || capacity.nan? || capacity >= UNLIMITED_CAPACITY

        capacity
      end

      # Typical input capacity × carrier conversion × number of units.
      #
      # @return [Float, nil] Capacity in MW, or nil if the node has no slot of the carrier or no
      #   input capacity
      def nameplate_capacity(carrier, direction)
        slot = direction == :input ? input(carrier) : output(carrier)

        return if slot.nil? || input_capacity.nil? || input_capacity.zero?

        slot.conversion * input_capacity * number_of_units
      end
    end
  end
end
