module Qernel::Plugins
  # TXT_TABLE(SORT_BY(G(merit_order_converters),merit_order_position),full_key,merit_order_full_load_hours)
  module MeritOrder
    extend ActiveSupport::Concern

    included do |variable|
      if merit_order_converters
        set_callback :calculate, :after, :calculate_merit_order
        set_callback :calculate, :after, :calculate_full_load_hours
      end
    end

    module ClassMethods

      def merit_order_table
        @merit_order_table ||= Etsource::Loader.instance.merit_order_table
      end

      def merit_order_converters
        @merit_order_converters ||= Etsource::Loader.instance.globals('merit_order_converters')
      end

    end

    module InstanceMethods

      def converters_for_merit_order
        group_converters(:merit_order_converters).map(&:query).tap do |arr|
          raise "MeritOrder: no converters in group: merit_order_converters. Update ETsource." if arr.empty?
        end
      end

      # assign merit_order_start and merit_order_end
      def calculate_merit_order
        return if group_converters(:merit_order_converters).empty?
        
        instrument("qernel.merit_order: calculate_merit_order") do
          # Converters to include in the sorting: G(electricity_production)
          converters = converters_for_merit_order
          converters.sort_by! do |c|
            c.variable_costs_per_mwh_input / c.electricity_output_conversion
          end

          if first = converters.first
            first[:merit_order_end]      = (first.installed_production_capacity_in_mw_electricity || 0.0) * first.availability
            first[:merit_order_start]    = 0.0
            first[:merit_order_position] = counter = 1

            converters[1..-1].each_with_index do |converter, i|
              # i points now to the previous one, not the current index! (because we start from [1..-1])
              # the merit_order_start of this 'converter' is the merit_order_end of the previous at 'i'.
              converter[:merit_order_start] = converters[i][:merit_order_end]
              installed_capacity = converter.installed_production_capacity_in_mw_electricity || 0.0
              
              merit_order_end = converter[:merit_order_start] + installed_capacity * converter.availability
              converter[:merit_order_end] = merit_order_end.round(3)

              # Assign a position at the end if installed_capacity is 0. Issue #293
              converter[:merit_order_position] = (installed_capacity > 0.0) ? (counter += 1) : 1000
            end
          end # if
          dataset_set(:calculate_merit_order_finished, true)
        end
      end # calculate_merit_order

      # 
      #
      def merit_order_demands
        instrument("qernel.merit_order: merit_order_demands") do
          self.class.merit_order_converters.map do |_ignore, converter_keys|
            converter_keys.map do |key|
              converter = converter(key)
              raise "merit_order: no converter found with key: #{key.inspect}" unless converter
              converter.query.instance_exec { mw_input_capacity * electricity_output_conversion * availability }
            end.sum.round(1)
          end
        end
      end

      # Adjust the loads by the demands of the converters defined in merit_order_converters.yml
      # It uses the tabular data merit_order.csv
      #
      # Returns an Array of x,y
      #
      def residual_load_profiles # Excel N
        instrument("qernel.merit_order: residual_load_profiles") do
          demands     = merit_order_demands
          peak_demand = group_converters(:final_demand_electricity).map{|c| c.query.mw_input_capacity }.sum

          self.class.merit_order_table.map do |normalized_load, wewp|
            load = peak_demand * normalized_load

            # take one column from the table and multiply it with the demands
            # defined in the merit_order_converters.yml
            wewp_x_demands = wewp.zip(demands) # [1,2].zip([3,4]) => [[1,3],[2,3]]
            wewp_x_demands.map!{|wewp, demand| wewp * demand }
            [0, load - wewp_x_demands.sum].max
          end
        end
      end

      def residual_ldc
        instrument("qernel.merit_order: residual_ldc") do
          loads      = []
          load_profiles        = residual_load_profiles
          load_profiles_length = load_profiles.length.to_f

          precision = 10

          (0..precision).to_a.each do |i|
            q = i / precision.to_f  * load_profiles.max
            y = load_profiles.count{|n| n >= q} / load_profiles_length
            loads << [q, y.to_f]
          end

          loads
        end
      end

      def calculate_full_load_hours
        return if group_converters(:merit_order_converters).empty?
        
        if dataset_get(:calculate_merit_order_finished) != true
          calculate_merit_order
        end

        ldc_points = residual_ldc
        y_max = residual_load_profiles.max

        converters = converters_for_merit_order
        converters.sort_by!{|c| c[:merit_order_end]}

        max_merit  = converters.last.andand[:merit_order_end] || 0.0

        instrument("qernel.merit_order: calculate_full_load_hours") do
          converters.each do |converter|
            lft = converter.merit_order_start
            rgt = converter.merit_order_end  
            
            points = [ # polygon_area expects the points passed in clock-wise order.
              [lft, 0],                                       # bottom left
              [lft, interpolate_y(ldc_points, lft, y_max)],   # top left (y interpolated)
              *ldc_points.select{|x,y| x > lft && x < rgt },  # points on residual_ldc curve
              [rgt, interpolate_y(ldc_points, rgt, y_max)],   # top right (y interpolated)
              [rgt, 0]                                        # bottom right
            ]

            area_size       = polygon_area(points.map(&:first), points.map(&:second))
            diff            = [rgt - lft, 0.0].max
            availability    = converter.availability

            capacity_factor = [availability * (area_size / diff).rescue_nan, availability].min
            full_load_hours = capacity_factor * 8760

            converter.merit_order_capacity_factor = capacity_factor.round(3)
            converter.merit_order_full_load_hours = full_load_hours.round(1)
            converter.number_of_units = nil
            converter.full_load_hours = full_load_hours.round(1) if enable_merit_order?
          end
        end

        nil
      end

      # this function is probably not so precise.
      # it's supposed to interpolate the y value for a given x.
      # It uses the formulas i've learned at school and wikipedia
      def interpolate_y(points, x, y_max)
        return 1.0 if x == 0.0
        return 0.0 if x >= y_max

        index = points.index{|px,y| px >= x } - 1
        index = 0 if index < 0

        x1,y1 = points[index]
        x2,y2 = points[index + 1]

        m = (y2 - y1) / (x2 - x1)
        n = y1 - ((y2 - y1)/(x2-x1)) * x1

        y = m*x + n

        y.rescue_nan
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
