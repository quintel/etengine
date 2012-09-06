module Qernel::Plugins
  # TXT_TABLE(SORT_BY(G(merit_order_converters),merit_order_position),code,merit_order_full_load_hours)
  module MeritOrder
    extend ActiveSupport::Concern

    included do |variable|
      # Only run if merit_order_converters.yml file is given.
      if Etsource::Loader.instance.globals('merit_order_converters')
        set_callback :calculate, :after, :calculate_merit_order
        set_callback :calculate, :after, :calculate_full_load_hours
      end
    end

    # ---- Converters ------------------------------------------------------------

    # For stubbing convenience
    def group_merit_order
      group_converters(:merit_order_converters)
    end

    # Converters to include in the sorting: G(electricity_production)
    def converters_for_merit_order
      group_merit_order.map(&:query).tap do |arr|
        raise "MeritOrder: no converters in group: merit_order_converters. Update ETsource." if arr.empty?
      end
    end

    # The total variable costs. Cheaper power plants should be used first.
    def converters_by_total_variable_cost
      converters_for_merit_order.sort_by do |c|
        c.variable_costs_per_mwh_input / c.electricity_output_conversion
      end
    end

    # ---- MeritOrder ------------------------------------------------------------

    # assign merit_order_start and merit_order_end
    def calculate_merit_order
      return if group_merit_order.empty?

      instrument("qernel.merit_order: calculate_merit_order") do
        converters = converters_by_total_variable_cost

        first = converters.first.tap{|c| c.merit_order_start = 0.0 }
        update_merit_order_end!(first)

        converters.each_cons(2) do |prev, converter|
          # the merit_order_start of this 'converter' is the merit_order_end of the previous.
          converter.merit_order_start = prev.merit_order_end
          update_merit_order_end!(converter)
        end

        calculate_merit_order_position(converters)

        dataset_set(:calculate_merit_order_finished, true)
      end
    end # calculate_merit_order

    # Updates the merit_order_position attributes. It assumes the given converters array
    # is already properly sorted by merit_order_start.
    #
    def calculate_merit_order_position(converters)
      position = 1
      converters.each do |converter|
        if (converter.installed_production_capacity_in_mw_electricity || 0) > 0.0
          converter.merit_order_position = position
          position += 1
        else
          converter.merit_order_position = 1000
        end
      end
    end

    # Assigns the merit_order_position attribute to a converter.
    # Assign a position at the end if installed_capacity is 0. Issue #293
    #
    # @return counter so we can keep track of the last assigned position
    #
    def update_merit_order_end!(converter)
      unless converter.merit_order_start
        raise "MeritOrder#update_merit_order_end! undefined merit_order_start for: #{converter.key}"
      end
      converter.merit_order_end = converter.merit_order_start

      inst_cap = converter.installed_production_capacity_in_mw_electricity || 0
      if inst_cap > 0.0
        converter.merit_order_end += (inst_cap * converter.availability).round(3)
      end
    end

    # ---- full_load_hours, capacity_factor  ----------------------------------

    def calculate_full_load_hours
      return unless area.area_code == 'nl'
      return if group_merit_order.empty?

      if dataset_get(:calculate_merit_order_finished) != true
        calculate_merit_order
      end

      instrument("qernel.merit_order: calculate_full_load_hours") do
        load_profile_curve = self.load_profile_curve
        converters = converters_for_merit_order.sort_by { |c| c.merit_order_end }

        converters.each do |converter|
          capacity_factor = capacity_factor_for(converter, load_profile_curve)
          full_load_hours = capacity_factor * 8760 # hours per year

          converter.merit_order_capacity_factor = capacity_factor.round(3)
          converter.merit_order_full_load_hours = full_load_hours.round(1)
        end
      end
      nil
    end

    # capacity_factor uses the LoadProfileTable. It get's the area between merit_order_start to -end
    #
    #
    #     |__
    #     |  --
    #     |   |x-----
    #     |   |xxxxx| ______
    #     |   |xxxxx|       ---
    #     +-------------------
    #        strt   end
    #
    # Total demand (? TODO: find a good name) :
    #   area_size / merit_span (= merit_end - merit_start)
    # capacity_factor:
    #   multiply above with the availability of a converter.
    #
    def capacity_factor_for(converter, profile_curve)
      merit_order_start = converter.merit_order_start
      merit_order_end   = converter.merit_order_end

      area_size    = profile_curve.area(merit_order_start, merit_order_end)
      merit_span   = [merit_order_end - merit_order_start, 0.0].max
      availability = converter.availability

      capacity_factor = [availability * (area_size / merit_span).rescue_nan, availability].min
    end

    # Create a CurveArea with the residual-ldc coordinates.
    # I resist the temptation to make an instance variable out of it, otherwise it'll persist
    # over requests and will cause mischief.
    def load_profile_curve
      coordinates = LoadProfileTable.new(self).residual_ldc_coordinates
      CurveArea.new(coordinates)
    end

    # --- LoadProfileTable ----------------------------------------------------

    #
    #
    #     |__
    #     |  --
    #     |     -----
    #     |          ______
    #     |                ---
    #     +--------------------
    #       400   1600        4000
    #
    #
    #
    class LoadProfileTable
      # Precision defines how many points will be calculated. E.g. how smooth the curve
      # is. So in this case #residual_ldc_coordinates_and_max_load will return 10 coordinates
      # for the curve.
      PRECISION = 10

      def initialize(graph)
        @graph = graph
      end

      # Returns an array of x,y coordinates and the max_load to be used with a CurveArea.
      #
      # We basically group the array of load profiles into n steps (n defined by PRECISION).
      #
      #   * x: the max of residual_load_profiles divided by the segment (e.g. 4000 * 0.1 => 400)
      #   * y: average number of residual_load_profiles that are higher then x?
      #
      #  [    0,   1    ] # all load_profiles are higher then 0
      #  [  400,   0.7  ] #
      #  [  800,   0.5  ] #
      #  ...
      #  [ 3500,   0.01 ] #
      #  [ 4000,   0    ] # Close to 0 profiles are >= 4000.
      #
      #
      #
      # @return [[[x,y], [x,y]], max_load]
      #
      def residual_ldc_coordinates
        load_profiles        = residual_load_profiles
        load_profiles_length = load_profiles.length
        max_load             = load_profiles.max

        steps = PRECISION

        (0..steps).map do |i|
          section      = i.fdiv(steps) * max_load
          loads_higher = load_profiles.count{ |n| n >= section }

          y = loads_higher.fdiv(load_profiles_length)
          [section, y]
        end
      end

      def merit_order_converters
        self.class.merit_order_converters(@graph)
      end

      def self.merit_order_converters(graph)
        unless @merit_order_converters
          @merit_order_converters = Etsource::Loader.instance.globals('merit_order_converters')
          # Fail early:
          @merit_order_converters.values.flatten.each do |key|
            unless graph.converter(key)
              raise "Qernel::Graph#merit_order: no converter found for #{key.inspect}. Update datasets/_globals/merit_order_converters.yml"
            end
          end
        end
        @merit_order_converters
      end

      #######
      private
      #######

      def graph_peak_demand
        @graph.group_converters(:final_demand_electricity).map{|c| c.query.mw_input_capacity }.compact.sum
      end

      # Adjust the loads by the demands of the converters defined in merit_order_converters.yml
      # It uses the tabular data from datasets/_globals/merit_order.csv
      #
      # It uses the *merit_order_table*
      #
      #      normalized,  column_1, column_2, column_3, column_4, column_5, column_6, column_7
      #     [ 0.6255066, [0.6186073,0.0000000,1.0000000,0.0002222,0.0000000,0.0000000,0.0000000]],
      #     [ 0.5601907, [0.6186073,0.0000000,1.0000000,0.0001867,0.0000000,0.0000000,0.0000000]],
      #
      # and the merit_order_demands. The 7 numbers sum an attribute for every group in merit_order_converters.yml
      #
      #                   column_1, column_2, column_3, column_4, column_5, column_6, column_7
      #     [             1000,      1500,      8000,     1000,       2000,    300000,   10000]
      #
      # It returns an array of the load profiles, adjusted by the demands.
      #
      #    [ (PeakLoad - ( 0.618*1000 + 0.000 * 1500, + 1.000 * 8000, 0.002* 1000, ...))]
      #    [ (PeakLoad - ( 0.618*1000 + 0.000 * 1500, + 1.000 * 8000, 0.0018*1000, ...))]
      #
      def residual_load_profiles # Excel N
        demands     = merit_order_demands
        peak_demand = graph_peak_demand

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
      # normalized,column_1, column_2, column_3, column_4, column_5, column_6, column_7
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
    class CurveArea
      attr_reader :points, :x_max

      # points    - An array of [x,y] coordinates for the line
      # x_max     - the maximum y
      def initialize(points)
        @points = points
        @x_max  = points.last.first
      end

      # Area below the curve, from x1 to x2.
      #
      #
      #
      def area(x_lft, x_rgt)
        coordinates = coordinates(x_lft, x_rgt)
        polygon_area(coordinates.map(&:first), coordinates.map(&:second))
      end

      #######
      private
      #######

      # returns x,y coordinates of the polygon_area in clock-wise order.
      #
      # @example: coordinates(2,7)
      #
      #     *
      #   5 |  o
      #   3 |      o
      #   1 |         o
      #     +--o------o--*
      #        2   5  7  10
      #
      # => [2,0], [2,5], [5,3], [7,1], [7,0]
      #
      def coordinates(x_lft, x_rgt)
        [
          [x_lft, 0],                                     # bottom left
          [x_lft, interpolate_y(x_lft)],                  # top left (y interpolated)
          *points.select{|x,y| x > x_lft && x < x_rgt },  # points on residual_ldc curve
          [x_rgt, interpolate_y(x_rgt)],                  # top right (y interpolated)
          [x_rgt, 0]                                      # bottom right
        ]
      end


      # it interpolates the y value for a given x.
      #
      #
      # It uses the formulas i've learned at school and wikipedia
      def interpolate_y(x)
        return points.first.last if x == 0.0
        return 0.0 if x >= x_max

        index = points.index{|px,y| px >= x } - 1
        index = 0 if index < 0

        x1,y1 = points[index]
        x2,y2 = points[index + 1]

        m = (y2 - y1) / (x2 - x1)
        n = y1 - ((y2 - y1)/(x2-x1)) * x1

        y = m*x + n

        y.rescue_nan
      end

      # The actual algorithm from http://alienryderflex.com/polygon_area/
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
    end # LdcCurveArea
  end # MeritOrder
end


