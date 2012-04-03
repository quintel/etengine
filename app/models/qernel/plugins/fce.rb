module Qernel::Plugins
  module Fce
    extend ActiveSupport::Concern

    FCE_ATTRIBUTES = [
      :co2_extraction_per_mj,
      :co2_transportation_per_mj,
      :co2_conversion_per_mj,
      :co2_exploration_per_mj,
      :co2_treatment_per_mj,
      :co2_waste_treatment_per_mj
    ].freeze


    included do |variable|
      set_callback :calculate, :after,  :calculate_fce
    end


    module ClassMethods

      def fce_values
        @fce_values ||= Etsource::Loader.instance.globals('fce_values').map{|f| 
          OpenStruct.new(f).freeze 
        }.freeze
      end

    end # ClassMethods



    module InstanceMethods

      def reset_temporary_fce_data
        @fce_update_values = {}
      end

      def calculate_fce
        @fce_update_values.andand.each do |carrier, values|
          values.each do |key, sum|
            carrier[key] = sum
          end
        end
        # reset fce_update_values so it is not accidentally used in another request
        # (graph is memoized over requests)
        @fce_update_values = nil
      end

      # carrier - The carrier key as a String 
      # origin  - The name of the origin as a String. E.g. australia, east_asi
      # country - The country code as a String
      #
      # Returns an Openstruct of FCE data.
      #
      def fce_value(carrier, origin, country)
        self.class.fce_values.andand.detect do |fce| 
          fce.carrier == carrier && fce.origin_country == origin && fce.using_country == country
        end
      end

      def update_fce(carrier, origin, value)
        # GQL CARRIER(...) gives back an array of carriers.
        carrier = [carrier].flatten.first
        fce = fce_value(carrier.key.to_s, origin.to_s, area.area.to_s)

        @fce_update_values ||= {}
        @fce_update_values[carrier] ||= {}
        FCE_ATTRIBUTES.each do |key| 
          @fce_update_values[carrier][key] ||= 0.0
          @fce_update_values[carrier][key] += fce.send(key) * value
        end
        nil
      end
    end # InstanceMethods

  end # Fce
end
