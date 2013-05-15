module Qernel::Plugins
  # Fce calculation updates a carriers co2_per_mj attribute.
  #
  # @example Updating coal carrier with an input gquery
  #   GRAPH().update_fce(CARRIER(coal),east_asia, USER_INPUT() / 100)
  #
  # The fce_values are read out of etsource/datasets/_globals/fce_values.yml
  #
  #
  module Fce
    extend ActiveSupport::Concern

    FCE_CARRIERS = [
      :crude_oil,
      :greengas,
      :wood_pellets,
      :coal,
      :natural_gas,
      :uranium_oxide,
      :biodiesel,
      :bio_ethanol
    ]

    included do |variable|
      set_callback :calculate, :after, :calculate_fce
    end

    def fce_enabled?
      use_fce
    end

    def calculate_fce
      @cache ||= {}
      FCE_CARRIERS.each do |carrier_key|
        # Get the carrier
        carrier = carrier(carrier_key)
        next unless carrier
        sum = 0

        if carrier.fce
          # The carrier has FCE "profiles" for each origin of country
          # or material.
          co2_attributes_for_calculation.each do |attribute|
            fce_values = carrier.fce.map do |fce_profile|
              key   = "#{carrier.key}_#{fce_profile['origin_country']}"
              value = @cache[key] || fce_profile['start_value']
              fce_profile[attribute.to_s] * (value / 100)
            end
            carrier[attribute] = fce_values.compact.sum
            sum += carrier[attribute]
          end
        else
          # The carrier doesn't have FCE "profiles, so we'll just use the
          # carrier properties instead.
          co2_attributes_for_calculation.each do |attribute|
            sum += carrier[attribute] || 0
          end
        end
        carrier.dataset_set(:co2_per_mj, sum)
      end

      # Reset the cache, as it's memoized between requests.
      @cache = {}
    end

    # Different attributes to consider if FCE is enabled or not.
    #
    def co2_attributes_for_calculation
      if fce_enabled?
        ::Qernel::Carrier::CO2_FCE_COMPONENTS
      else
        [:co2_conversion_per_mj]
      end
    end

    # Method that the graph uses to get start values for a specific FCE
    # profile.
    #
    def fce_start_value(carrier_key, origin)
      if carrier_key.is_a?(Symbol)
        carrier = carrier(carrier_key)
      elsif carrier_key.is_a?(Array)
        carrier = carrier_key.flatten[0]
      else
        carrier = carrier_key
      end


      key = "#{carrier.key}_#{origin}"
      return @cache[key] if @cache[key]

      return 0.0 unless carrier.fce

      fce_profiles = carrier.fce.select { |fp|
        fp["origin_country"] == origin.to_s
      }

      if fce_profile = fce_profiles.first
        fce_profile["start_value"]
      else
        0.0
      end
    end

    def update_fce(carrier, origin, user_input)
      key = "#{carrier[0].key}_#{origin}"
      @cache ||= {}
      @cache[key] = user_input * 100
      nil
    end
  end # Fce
end
