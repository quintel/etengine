module Qernel::Plugins

  module MeritOrder
    extend ActiveSupport::Concern

    included do |variable|
      set_callback :calculate, :after, :calculate_merit_order
      # set_callback :calculate, :after, :calculate_full_load_hours
    end

    module ClassMethods

    end

    MERIT_ORDER_CONVERTERS = [
      # the converter keys that correspond to the number array in MERIT_ORDER_DATA
      :industrial_chp,
      :agriculture_chp,
      :space_heating_chp,
      :wind_offshore,
      :wind_coastal,
      :wind_inland
    ]

    require 'csv'
    MERIT_ORDER_DATA = ::CSV.read('../etsource/datasets/_globals/merit_order.csv', :converters => :numeric)
    MERIT_ORDER_DATA.map! do |row|
      [row.delete_at(0), row]
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
            converter[:merit_order_end] = e.round(3)
          end
        end # if
        dataset_set(:calculate_merit_order_finished, true)
        calculate_full_load_hours
      end # calculate_merit_order

      def normalized_residual_loads # Excel N

        demands = [3946, 2973, 394, 20000,0,0,0]
        residual_load_profiles = MERIT_ORDER_DATA.map do |load, wewp|
          wewp_x_demands = wewp.zip(demands)
          wewp_x_demands.map!{|wewp, demand| wewp * demand }
          [0, load - wewp_x_demands.sum].max
        end
        max = residual_load_profiles.max

        # only interested in the normalized loads. so map! 
        residual_load_profiles.map!{|l| l / max}
      end

      def residual_ldc
        loads      = []
        nrl        = normalized_residual_loads
        nrl_length = nrl.length.to_f

        precision = 10

        (0..precision).to_a.each do |i| 
          q = i / precision.to_f
          y = nrl.count{|n| n >= q} / nrl_length
          loads << [q, y.to_f]
        end

        loads
      end

      def calculate_full_load_hours
        if dataset_get(:calculate_merit_order_finished) != true
          raise "Trying to calculate_full_load_hours before calculate_merit_order has started/finished!" 
        end
        ldc_points = residual_ldc

        converters = group_converters(:electricity_production).map(&:query)
        converters.sort_by!{|c| c[:merit_order_end]}
        
        max_merit  = converters.last[:merit_order_end] || 0.0
        
        converters.each do |converter|
          s = (converter[:merit_order_start]) / max_merit
          e = (converter[:merit_order_end]  ) / max_merit
          diff = [e - s, 0.001].max

          # polygon_area expects the points passed in clock-wise order.
          points  = [[s, 0]]
          points << [s, interpolate_y(ldc_points, s)]     # top left (y interpolated)
          ldc_points.each do |p|
            x = p.first
            points << p if x > s && x < e # in between
          end
          points << [e, interpolate_y(ldc_points, e)]     # top right (y interpolated)
          points << [e, 0]                                # bottom right

          area_size = polygon_area(points.map(&:first), points.map(&:second))

          capacity_factor = area_size / diff
          full_load_hours = capacity_factor * 8760

          converter[:capacity_factor] = capacity_factor
          converter[:full_load_hours] = full_load_hours.finite? ? full_load_hours.round(1) : 0.0
        end

        nil
      end

      def interpolate_y(points, x)
        return 1.0 if x == 0.0
        return 0.0 if x >= 1.0

        index = points.index{|px,y| px >= x } - 1
        index = 0 if index < 0

        x1,y1 = points[index]
        x2,y2 = points[index + 1]

        m = (y2 - y1) / (x2 - x1)
        n = y1 - ((y2 - y1)/(x2-x1)) * x1

        y = m*x + n

        y.finite? ? y : 0.0
      end

      # Inspired from http://alienryderflex.com/polygon_area/
      # points have to be passed in "around the clock" direction
      def polygon_area(x_arr, y_arr)
        points = x_arr.length
        i = points - 1
        j = points - 1

        area = 0.0
        0.upto(points - 1) do |i|
          area += (x_arr[j] + x_arr[i])*(y_arr[j] - y_arr[i])
          j = i
        end
        area * 0.5
      end

    end # InstanceMethods
  end # MeritOrder
end