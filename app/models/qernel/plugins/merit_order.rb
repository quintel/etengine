module Qernel::Plugins
  # TXT_TABLE(SORT_BY(G(merit_order_converters),merit_order_position),code,merit_order_full_load_hours)
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

    # Converters to include in the sorting: G(electricity_production)
    def converters_for_merit_order
      group_converters(:merit_order_converters).map(&:query).tap do |arr|
        raise "MeritOrder: no converters in group: merit_order_converters. Update ETsource." if arr.empty?
      end
    end

    # assign merit_order_start and merit_order_end
    def calculate_merit_order
      return if group_converters(:merit_order_converters).empty?

      instrument("qernel.merit_order: calculate_merit_order") do
        converters = converters_for_merit_order.sort_by do |c|
          c.variable_costs_per_mwh_input / c.electricity_output_conversion
        end

        if first = converters.first
          first[:merit_order_start] = 0.0
          update_merit_order_end!(first)

          counter = 0 # keep track of the counter, it is incremented by #update_merit_order_pos!
          counter = update_merit_order_pos!(first, counter)

          converters.each_cons(2) do |prev, converter|
            # the merit_order_start of this 'converter' is the merit_order_end of the previous.
            converter[:merit_order_start] = prev[:merit_order_end]

            update_merit_order_end!(converter)
            counter = update_merit_order_pos!(converter, counter)
          end
        end # if
        dataset_set(:calculate_merit_order_finished, true)
      end
    end # calculate_merit_order

    # Assigns the merit_order_position attribute to a converter.
    # Assign a position at the end if installed_capacity is 0. Issue #293
    #
    # @return counter so we can keep track of the last assigned position
    #
    def update_merit_order_pos!(converter, counter)
      installed_capacity = converter.installed_production_capacity_in_mw_electricity || 0.0
      converter[:merit_order_position] = (installed_capacity > 0.0) ? (counter += 1) : 1000

      counter
    end

    def update_merit_order_end!(converter)
      installed_capacity = converter.installed_production_capacity_in_mw_electricity || 0.0
      merit_order_end    = converter[:merit_order_start] + (installed_capacity * converter.availability)
      converter[:merit_order_end] = merit_order_end.round(3)
    end


    def calculate_full_load_hours
      return unless area.area_code == 'nl'
      return unless group_converters(:merit_order_converters).present?

      if dataset_get(:calculate_merit_order_finished) != true
        calculate_merit_order
      end

      # Create a polygon area with the residual-ldc coordinates.
      # I resist the temptation to make an instance variable out of it, otherwise it'll persist
      # over requests and will cause mischief.
      coordinates = LoadProfileTable.new(self).residual_ldc_coordinates_and_max_load
      ldc_polygon = PolgyonArea.new(*coordinates)

      converters  = converters_for_merit_order.sort_by { |c| c[:merit_order_end] }

      instrument("qernel.merit_order: calculate_full_load_hours") do
        converters.each do |converter|
          capacity_factor = capacity_factor_for(converter, ldc_polygon)
          full_load_hours = capacity_factor * 8760 # hours per year

          converter.merit_order_capacity_factor = capacity_factor.round(3)
          converter.merit_order_full_load_hours = full_load_hours.round(1)
        end
      end

      nil
    end

    def capacity_factor_for(converter, ldc_polygon)
      merit_order_start = converter.merit_order_start
      merit_order_end   = converter.merit_order_end

      area_size       = ldc_polygon.area(merit_order_start, merit_order_end)
      delta           = [merit_order_end - merit_order_start, 0.0].max
      availability    = converter.availability

      capacity_factor = [availability * (area_size / delta).rescue_nan, availability].min
    end

    # --- LoadProfileTable ----------------------------------------------------


    #
    #
    #
    #
    class LoadProfileTable
      def initialize(graph)
        @graph = graph
      end

      # Returns an array of x,y coordinates and the max_load to be used with a PolgyonArea
      #
      # @return [[[x,y], [x,y]], max_load]
      #
      def residual_ldc_coordinates_and_max_load
        load_profiles        = residual_load_profiles
        load_profiles_length = load_profiles.length.to_f
        max_load             = load_profiles.max
        # TODO: what is precision?
        precision = 10

        loads = (0..precision).map do |i|
          q = i / precision.to_f * max_load
          y = load_profiles.count{ |n| n >= q } / load_profiles_length
          [q, y.to_f]
        end

        [loads, max_load]
      end


      def merit_order_converters
        unless @merit_order_converters
          @merit_order_converters = Etsource::Loader.instance.globals('merit_order_converters')#.values
          #@merit_order_converters = keys.flatten.map {|key| @graph.converter(key)}
        end
        @merit_order_converters
      end

      #######
      private
      #######

      # Adjust the loads by the demands of the converters defined in merit_order_converters.yml
      # It uses the tabular data merit_order.csv
      #
      # Returns an Array of x,y
      #
      def residual_load_profiles # Excel N
        demands     = merit_order_demands
        peak_demand = @graph.group_converters(:final_demand_electricity).map{|c| c.query.mw_input_capacity }.compact.sum

        merit_order_table.map do |normalized_load, wewp|
          load = peak_demand * normalized_load

          # take one column from the table and multiply it with the demands
          # defined in the merit_order_converters.yml
          wewp_x_demands = wewp.zip(demands) # [1,2].zip([3,4]) => [[1,3],[2,4]]
          wewp_x_demands.map!{|wewp, demand| wewp * demand }
          [0, load - wewp_x_demands.sum].max
        end
      end

      # Returns the "demands" (?) for the converters defined in merit_order_converters.yml.
      #
      # Returns an array of sums for every column_X group, like this:
      #
      # [
      #    247.3,    # [23.2, 211.1, 23.0].sum derived from the column_1: ... converters.
      #    100.1     # [50, 50.1].sum derived from the column_1: ... converters.
      # ]
      #
      def merit_order_demands
        merit_order_converters.map do |_ignore_column, converter_keys|
          converter_keys.map do |key|
            converter = @graph.converter(key)
            begin
              converter.query.instance_exec { mw_input_capacity * electricity_output_conversion * availability }
            rescue
              # We've been getting errors with nil attributes. Debug info
              debug = [:mw_input_capacity, :electricity_output_conversion, :availability].map do |a|
                "#{a}: #{converter.query.send a}"
              end.join "\n"
              raise "Error with converter #{key}: #{debug}"
            end
          end.sum.round(1)
        end
      end

      # Load merit_order.csv and create an array of arrays.
      # The merit_order.csv has to be in sync with merit_order_converters.yml
      # The columns correspond to the column_1, column_2, ... keys in that file.
      #
      #            column_1, column_2, column_3, column_4, column_5, column_6, column_7
      # 0.6255066,0.6186073,0.0000000,1.0000000,0.0002222,0.0000000,0.0000000,0.0000000
      # 0.5601907,0.6186073,0.0000000,1.0000000,0.0001867,0.0000000,0.0000000,0.0000000
      #
      # @return Array that looks like this:
      #
      # [ [0.6255066,[0.6186073,0.0000000,1.0000000,0.0002222,0.0000000,0.0000000,0.0000000]],
      #   [0.5601907,[0.6186073,0.0000000,1.0000000,0.0001867,0.0000000,0.0000000,0.0000000]]  ]
      #
      def merit_order_table
        @merit_order_table ||= Etsource::Loader.instance.merit_order_table
      end
    end


    # Given a line with x,y coordinates, PolygonArea will calculate
    # the area below that line from a x_1 to x_2.
    #
    #     The polgyon area               What's the area?
    #
    #     |__                            |__
    #     |  --                          |  --
    #     |     -----                    |   |x-----
    #     |          ______              |   |xxxxx| ______
    #     |                ---           |   |xxxxx|       ---
    #     +-------------------           +-------------------
    #                                       lft   rgt
    #
    # The algorithm is inspired from http://alienryderflex.com/polygon_area/
    # points have to be passed in "around the clock" direction
    #
    # @example
    #
    #   poly = LdcPolygonArea.new()
    #   poly.area( converter ) # => ...
    #
    class PolgyonArea
      attr_reader :points, :y_max

      # points    - An array of [x,y] coordinates for the line
      # y_max     - the maximum y
      def initialize(points, y_max)
        @points = points
        @y_max = y_max
      end

      def area(x_lft, x_rgt)
        coordinates = coordinates(x_lft, x_rgt)
        polygon_area(coordinates.map(&:first), coordinates.map(&:second))
      end

      private

      # returns x,y coordinates of the polygon_area in clock-wise order.
      def coordinates(x_lft, x_rgt)
        [
          [x_lft, 0],                                     # bottom left
          [x_lft, interpolate_y(points, x_lft, y_max)],   # top left (y interpolated)
          *points.select{|x,y| x > x_lft && x < x_rgt },  # points on residual_ldc curve
          [x_rgt, interpolate_y(points, x_rgt, y_max)],   # top right (y interpolated)
          [x_rgt, 0]                                      # bottom right
        ]
      end

      # this function is not too precise.
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
    end # LdcPolgyonArea
  end # MeritOrder
end


