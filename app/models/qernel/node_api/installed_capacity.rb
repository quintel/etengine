# frozen_string_literal: true

module Qernel
  module NodeApi
    # Methods to get the installed capacity of a node per carrier and direction
    #
    # The installed capacity is taken from, in order:
    # - Values set by Causality modules after hourly calculations
    #   (see MeritFacade::Adapter and Reconciliation::Adapter#inject_installed_capacity!)
    # - Typical input capacity * carrier conversion * number of units, for participants without a
    #   capacity of their own (such as Merit consumers) and nodes outside the calculations
    # - The peak of the hourly curve, for nodes without any capacity: demand, losses and nodes set by
    #   the balance of the carrier
    #
    # These methods are only used by the capacity data exports. The existing capacity methods
    # (Cost#input_capacity, CapacityProduction) are left untouched and are to be merged into this
    # module later.
    module InstalledCapacity
      # Installed electricity input capacity.
      #
      # @return [Float] Installed capacity
      def electricity_input_installed_capacity
        installed_capacity(:electricity, :input)
      end

      # Installed electricity output capacity.
      #
      # @return [Float] Installed capacity
      def electricity_output_installed_capacity
        installed_capacity(:electricity, :output)
      end

      # Installed hydrogen input capacity.
      #
      # @return [Float] Installed capacity
      def hydrogen_input_installed_capacity
        installed_capacity(:hydrogen, :input)
      end

      # Installed hydrogen output capacity.
      #
      # @return [Float] Installed capacity
      def hydrogen_output_installed_capacity
        installed_capacity(:hydrogen, :output)
      end

      # Installed network gas input capacity.
      #
      # @return [Float] Installed capacity
      def network_gas_input_installed_capacity
        installed_capacity(:network_gas, :input)
      end

      # Installed network gas output capacity.
      #
      # @return [Float] Installed capacity
      def network_gas_output_installed_capacity
        installed_capacity(:network_gas, :output)
      end

      # Installed steam hot water input capacity.
      #
      # @return [Float] Installed capacity
      def steam_hot_water_input_installed_capacity
        installed_capacity(:steam_hot_water, :input)
      end

      # Installed steam hot water output capacity.
      #
      # @return [Float] Installed capacity
      def steam_hot_water_output_installed_capacity
        installed_capacity(:steam_hot_water, :output)
      end

      private

      # Installed capacity of the node
      # Either:
      # 1. Installed capacity set by causality module calculations (eg merit)
      # 2. Typical installed capacity (conversion * input cap * number of units)
      # 3. The peak of its input/output curve (fallback)
      # 4. Zero
      #
      # @return [Float] Installed capacity
      def installed_capacity(carrier, direction)
        dataset_get(:"#{carrier}_#{direction}_installed_capacity") ||
          typical_installed_capacity(carrier, direction) ||
          public_send(:"#{carrier}_#{direction}_curve")&.max ||
          0.0
      end

      # Typical input capacity x carrier conversion x number of units.
      #
      # @return [Float, nil] Capacity, or nil if the node has no slot of the carrier or no
      #   input capacity
      def typical_installed_capacity(carrier, direction)
        slot = direction == :input ? input(carrier) : output(carrier)

        return if slot.nil? || input_capacity.nil? || input_capacity.zero?

        slot.conversion * input_capacity * number_of_units
      end
    end
  end
end
