module Qernel::Plugins

  module MeritOrder
    extend ActiveSupport::Concern

    included do |variable|
      set_callback :calculate, :after, :calculate_merit_order
    end
    
    module InstanceMethods
      def calculate_merit_order
        # Converters to include in the sorting: G(electricity_production)
        converters = group_converters(:electricity_production).map(&:query)
        converters.sort_by! do |c| 
          c.variable_costs_per_mwh_input * c.electricity_output_conversion
        end

        if converters.first
          converters.first[:merit_order_end]   = 0.0
          converters.first[:merit_order_start] = 0.0
          converters[1..-1].each_with_index do |converter, i|
            # i points now to the previous one, not the current index! (because we start from [1..-1])
            converter[:merit_order_start] = converters[i][:merit_order_end]
            
            e  = converter[:merit_order_start]
            e += (converter.installed_production_capacity_in_mw_electricity || 0.0) * converter.availability
            converter[:merit_order_end] = e
          end
        end
      end
    end
  end
end