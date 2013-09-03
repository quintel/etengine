module Qernel::Plugins
  # Fce calculation updates a carriers co2_per_mj attribute.
  #
  # @example Updating coal carrier with an input gquery
  #   GRAPH().update_fce(CARRIER(coal),east_asia, USER_INPUT() / 100)
  #
  # The fce_values are read out of etsource/datasets/_globals/fce_values.yml
  #
  # TODO: check out whether we can replace @cache with (Scenario)#user_values.
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

    def calculate_fce
      @cache ||= {}

      FCE_CARRIERS.each do |carrier_key|
        # Get the carrier
        carrier = carrier(carrier_key)
        next unless carrier

        co2_per_mj = 0
        fce_values = {}

        if carrier.fce
          # The carrier has FCE "profiles" for each origin of country
          # or material. First we calculate the attributes separately,
          # and we have to do it on all of them.
          ::Qernel::Carrier::CO2_FCE_COMPONENTS.each do |attribute|
            fce_values[attribute] = carrier.fce.map do |fce_profile|
              fce_profile[attribute.to_sym] * fce_start_value(carrier, fce_profile[:origin_country]) / 100
            end
            carrier[attribute] = fce_values[attribute].sum
          end

          # Then, we calculate the CO2 emissions per MJ.
          co2_attributes_for_calculation.each do |attribute|
            co2_per_mj += carrier[attribute]
          end
        else
          # The carrier doesn't have FCE "profiles", so we'll just use the
          # carrier properties instead.
          co2_attributes_for_calculation.each do |attribute|
            co2_per_mj += carrier[attribute] || 0
          end
        end
        carrier.dataset_set(:co2_per_mj, co2_per_mj)
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

    # Returns true or false if fce is enabled for this scenario.
    def fce_enabled?
      use_fce
    end

    # Method that the graph uses to get start values for a specific FCE
    # profile.
    #
    def fce_start_value(carrier_key, origin)
      # DEBT: currently, it is called sometimes with carrier_key as a Symbol
      # and other times as an Array..
      # TODO: needs to be cleaned up.
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

      fce_profiles = carrier.fce.select do |fp|
        # TODO: rename to 'origin'
        fp[:origin_country] == origin.to_s
      end

      if fce_profile = fce_profiles.first
        fce_profile[:start_value]
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
