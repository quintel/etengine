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

    FCE_ATTRIBUTES = ::Qernel::Carrier::CO2_FCE_COMPONENTS

    included do |variable|
      set_callback :calculate, :after,  :calculate_fce
    end


    module ClassMethods

      def fce_values
        @fce_values ||= (Etsource::Loader.instance.globals('fce_values') || []).map{|f|
          OpenStruct.new(f).freeze
        }.freeze
      end

    end # ClassMethods

    def reset_temporary_fce_data
      @fce_update_values = {}
    end

    # calculate_fce
    #
    #
    def calculate_fce
      modified_fce_values_by_carrier.each do |carrier_key, fce_values|
        carrier = carrier(carrier_key)
        sum = 0

        attributes_for_fce = attributes_to_consider
        attributes_to_consider(true).each do |attr_name|
          # if use_fce is disabled assign all attributes, but only 
          # overwrite the co2_per_mj with the sum of co2_conversion_per_mj.
          carrier[attr_name] = fce_values.map do |f| 
            f.send(attr_name) * (f.start_value / 100.0)
          end.compact.sum

          sum += carrier[attr_name] if attributes_for_fce.include?(attr_name)
        end
        
        carrier.dataset_set(:co2_per_mj, sum)
      end
      
      # reset fce_update_values so it is not accidentally used in another request
      # (graph is memoized over requests)
      @fce_update_values = nil
    end

    def attributes_to_consider(_use_fce = use_fce)
      if _use_fce
        FCE_ATTRIBUTES
      else
        [:co2_conversion_per_mj]
      end
    end

    # a clone of the original fce_values for the current country.
    # the values are read from etsource/datasets/_globals/fce_values.yml
    def modified_fce_values_by_carrier
      unless @fce_update_values
        area_code = area.area.to_s
        arr = Marshal.load(Marshal.dump(self.class.fce_values))
        arr.select!{|fce| fce.using_country == area_code }
        @fce_update_values = arr.group_by(&:carrier)
      end
      @fce_update_values
    end

    # Update a carriers fce values (co2_extraction, co2_treatment_per_mj)
    # with the values defined in fce_values.yml multiplied by the users input
    # (the share of).
    #
    # This method is called by update statements.
    def update_fce(carrier, origin, user_input)
      # GQL CARRIER(...) gives back an array of carriers.
      carrier     = [carrier].flatten.first
      carrier_key = carrier.key.to_s
      origin      = origin.to_s

      fce_values = modified_fce_values_by_carrier[carrier_key] || []
      if fce_ostruct = fce_values.detect{|f| f.origin_country == origin }
        attributes_to_consider.each do |key|
          fce_ostruct.start_value = user_input * 100.0
        end
      end
      nil
    end
  end # Fce
end
