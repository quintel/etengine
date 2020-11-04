module Qernel::Plugins
  # FCE calculation updates carrier attributes related to fuel-chain emissions,
  # such as co2_per_mj.
  #
  # For example:
  #
  #   # Updating coal carrier with an input gquery
  #   GRAPH().update_fce(CARRIER(coal), east_asia, USER_INPUT() / 100)
  #
  class FCE
    include Plugin

    delegate :update, :share_of, :calculate_carrier, to: :calculator

    after :calculation, :inject

    # Keys of carriers whose CO2 attributes should be calculated by the FCE
    # plugin.
    FCE_CARRIERS = %i[
      biodiesel
      bio_ethanol
      coal
      crude_oil
      diesel
      gasoline
      greengas
      heavy_fuel_oil
      imported_electricity
      imported_heat
      kerosene
      natural_gas
      non_biogenic_waste
      lng
      lpg
      uranium_oxide
      wood_pellets
    ].freeze

    def self.enabled?(graph)
      graph.energy?
    end

    def calculator
      @calculator ||= FCECalculator.new(@graph.area.area_code, @graph.use_fce)
    end

    # Internal: After the graph has been calculated, adjusts FCE-related
    # attributes on appropriate carriers.
    #
    # Returns nothing.
    def inject
      # Calculate FCE attributes for each carrier.
      FCE_CARRIERS.each do |carrier_key|
        next unless qcarrier = @graph.carrier(carrier_key)

        calculator.calculate_carrier(carrier_key).each do |attribute, value|
          qcarrier[attribute] = value
        end
      end
    end

    # Calculates FCE-related values.
    class FCECalculator
      def initialize(area_code, enabled = false)
        @fce_enabled = enabled
        @area_code   = area_code.to_sym
        @values      = {}
      end

      # Public: Sets the user ("start") value for a carrier and origin pair.
      #
      # carrier_key - The carrier key, as a string or symbol.
      # origin      - The name of the origin of the carrier, as a string or
      #               symbol (e.g. "middle_east", "australia").
      # value       - The Numeric value to set set.
      #
      # Returns the value.
      def update(carrier_key, origin, value)
        @values[key(carrier_key, origin)] = value
      end

      # Public: The user-set, or default, start value for the carrier and origin
      # pair.
      #
      # carrier_key - The carrier key, as a string or symbol.
      # origin      - The name of the origin of the carrier, as a string or
      #               symbol (e.g. "middle_east", "australia").
      #
      # Returns a numeric.
      def share_of(carrier_key, origin)
        if @values[key(carrier_key, origin)]
          @values[key(carrier_key, origin)]
        elsif profile = Atlas::Carrier.find(carrier_key).fce(@area_code)
          profile[origin][:start_value]
        else
          0.0
        end
      end

      # Public: Determines the FCE-derived values for the named carrier.
      #
      # carrier_key - The key of the carrier to be calculated.
      #
      # Returns a numeric.
      def calculate_carrier(carrier_key)
        carrier = Atlas::Carrier.find(carrier_key)

        if (fce_data = carrier.fce(@area_code))
          base_attributes = calculate_fce_attributes(carrier.key, fce_data)
          base_attributes.merge!(co2_per_mj: calculate_co2(base_attributes))
        else
          { co2_per_mj: calculate_co2(carrier.attributes) }
        end
      end

      #######
      private
      #######

      # Internal: Given a carrier key and origin, returns the key used to store
      # values in the internal +@values+ hash.
      #
      # Returns a symbol.
      def key(carrier_key, origin)
        :"#{ carrier_key }_#{ origin }"
      end

      # Internal: With the given +fce_data+ – FCE data for the carrier in a
      # given country – calculates each of the FCE attributes depending on the
      # values selected by the user for each of the possible "origins" of the
      # carrier.
      #
      # Returns a hash of calculated attributes.
      def calculate_fce_attributes(carrier, fce_data)
        fce_data.each_with_object({}) do |(origin, profile), data|
          share = share_of(carrier, origin)

          # Iterating through each "origin" in the FCE data.
          Qernel::Carrier::CO2_FCE_COMPONENTS.each do |attr|
            data[attr] ||= 0.0
            data[attr] += profile[attr] * share
          end
        end
      end

      # Internal: Calculates the co2_per_mj attribute for the carrier based on
      # the values of the other FCE attributes.
      #
      # Returns the co2_per_mj as a float.
      def calculate_co2(fce_values)
        co2_attributes_for_calculation.reduce(0.0) do |sum, attribute|
          sum + (fce_values[attribute] || 0.0)
        end
      end

      # Internal: An array of attributes which should be used when calculating
      # the co2_per_mj of a carrier.
      #
      # Returns an array of symbols.
      def co2_attributes_for_calculation
        if @fce_enabled
          Qernel::Carrier::CO2_FCE_COMPONENTS
        else
          [ :co2_conversion_per_mj ]
        end
      end
    end # FCECalculator
  end # FCE
end # Qernel::Plugins
