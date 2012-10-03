# Schematic of Merit Order calculation
# ==========================================================================================================
#
#    FD HH Electr.                                                          G(merit_order_converters)
#    +-----------+                                                              +------------+
#    |           |                                                              |            |
#    |           |                                                 +--- c ----->|            |
#    +-----------+                 +---------------------+         |  dmd: 200  |            |
#                                  | Energy Network      |         |            +------------+
#                                  |---------------------|         |
#                                  |                     |         |
#                                  |                     +---------+            +------------+
#                                  |                     |         |            |            |
#                                  |                     |         +--- c ----->|            |
#                                  +---------------------+         |  dmd: 100  |            |
#                                          ^                       |            +------------+
#                                          |                       |     ^               ^
#                                +---------+                       F!    |               |   MeritOrder
#                                |                                 |     +- - - - -+     +- - - --+
#    FD Industry Electr.         |                                 |               |
#     +----------+               |                                 |   +-----+     +
#     |          +---------------+                                 +-->|     |  |--O-----| Slider no of
#     |          |               |                                     |     |
#     +----------+               |              must_run_merit_order   +-----+
#                                |               +-------------+
#                                |               |             |
#                                +-------------->|             |
#   +--------------+                             |             |
#   +--------------+                             +-------------+
#                                              industry chp combined gas power
#   SUM = graph_peak_power                     SUM(mw_power * electr_output_conversion * availability)
#
# ==========================================================================================================
#
# Merit Order is influenced among others by sliders:
# --------------------------
# * that update number_of_units of plants
#   => This also overwrites the preset demand of these demands
# * update costs for energy carriers
# * other changes to final electricity demand
#
# A) Before calculation:
# --------------------------
# * Set a calculation breakpoint to output slots of dispatchable merit order plants.
#
# B) Calculation
# --------------------------
# 1. Graph calculates up to dispatchable merit order plants (they have break-points)
#
# C) Merit-order breakpoint.
# --------------------------
# 2. MO calculates FLH (based on number_of_units, capacities and availabilities of plants,
#    combined with demand from HV network)
# 3. FLH from MO calculation are injected into dispatchable plants
# 4. Dispatchable plants get a new energy flow assigned (based on number_of_units, capacities
#    and availabilities of plants and new FLH).
#
# D) Resume calculation from breakpoint
# --------------------------
# 5. Outgoing reversed flexible links from dispatchable MO plants are updated
# 6. Inverse links to HV network are updated
# 7. Graph calculation commences at dispatchable MO plants
#
#
#
#
module Qernel::Plugins
  # TXT_TABLE(SORT_BY(G(merit_order_converters),merit_order_position),key,merit_order_full_load_hours)
  module MeritOrder
    extend ActiveSupport::Concern

    included do |variable|
      # Only run if must_run_merit_order_converters.yml file is given.
      if Etsource::Loader.instance.globals('must_run_merit_order_converters')
        # set_callback :calculate, :before, :assign_breakpoint_to_dispatchable_merit_order_converters
        set_callback :calculate, :after,  :calculate_merit_order
        set_callback :calculate, :after,  :calculate_full_load_hours
      end
    end

    # ---- Converters ------------------------------------------------------------

    # Select dispatchable merit order converters
    def dispatchable_merit_order_converters
      group_converters(:merit_order_converters)
    end

    # Converters to include in the sorting: G(merit_order_converters)
    # returns array of converter objects
    def dispatchable_converters_for_merit_order
      dispatchable_merit_order_converters.map(&:query).tap do |arr|
        raise "MeritOrder: no converters in group: merit_order_converters. Update ETsource." if arr.empty?
      end
    end

    # Sort dispatschable converters by their total variable costs. Cheaper power plants should be used first.
    # returns (sorted) array of converter objects
    def converters_by_total_variable_cost
      dispatchable_converters_for_merit_order.sort_by do |c|
        # Sort by the variable costs of electricity output per MWh
        c.variable_costs_per(:mwh_electricity) rescue nil
      end
    end

    # ---- MeritOrder ------------------------------------------------------------

    # Assign merit_order_start and merit_order_end
    def calculate_merit_order
      return if dispatchable_merit_order_converters.empty?

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
    # is already properly sorted by merit_order_start attribute.
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

    # Assign full load hours and capacity factors to dispatchable converters
    def calculate_full_load_hours
      return unless area.area_code == 'nl'
      return if dispatchable_merit_order_converters.empty?

      if dataset_get(:calculate_merit_order_finished) != true
        calculate_merit_order
      end

      instrument("qernel.merit_order: calculate_full_load_hours") do
        residual_load_duration_curve = self.residual_load_duration_curve
        converters = dispatchable_converters_for_merit_order.sort_by { |c| c.merit_order_end }

        converters.each do |converter|
          capacity_factor = capacity_factor_for(converter, residual_load_duration_curve)
          full_load_hours = capacity_factor * 8760 # hours per year

          converter.merit_order_capacity_factor = capacity_factor.round(3)
          converter.merit_order_full_load_hours = full_load_hours.round(1)
        end
      end
      nil
    end

    # Returns capacity factors for converters given the residual_load_duration_curve
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
    # capacity_factor = availability * area_size / merit_span (= merit_end - merit_start)
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
    # SB: I resist the temptation to make an instance variable out of it, otherwise it'll persist
    # over requests and will cause mischief.
    def residual_load_duration_curve
      coordinates = LoadProfileTable.new(self).residual_ldc_coordinates
      CurveArea.new(coordinates)
    end

    # --- LoadProfileTable ----------------------------------------------------
    #
    #     |__
    #     |  --
    #     |     -----
    #     |          ______
    #     |                ---
    #     +--------------------
    #       400   1600        4000
    #
    class LoadProfileTable
      # Precision defines how many points will be calculated. E.g. how smooth the curve
      # is. So in this case #residual_ldc_coordinates and max_load will return 10 coordinates
      # for the curve.
      PRECISION = 10

      def initialize(graph)
        @graph = graph
      end

      # Returns an array of x,y coordinates and the max_load to be used with a CurveArea.
      #
      # We basically group the residual load profile into n bins (n defined by PRECISION).
      #
      #   * x: the max of residual_load_profiles divided by the number of bins (PRECISION)
      #   (e.g. for N = 10 and max_load = 4000: size of bins in MW = 4000 * 0.1 => 400)
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
      # @return [[x,y], [x,y], ... ]
      #
      def residual_ldc_coordinates
        load_profiles        = residual_load_profiles
        load_profiles_length = load_profiles.length
        max_load             = load_profiles.max

        steps = PRECISION

        (0..steps).map do |i|
          section      = i.fdiv(steps) * max_load
          loads_higher = load_profiles.count{ |n| n >= section }

          # Normalize the frequencies to unit interval
          y = loads_higher.fdiv(load_profiles_length)
          # making [x, y] array
          [section, y]
        end
      end

      def must_run_merit_order_converters
        self.class.must_run_merit_order_converters(@graph)
      end

      def self.must_run_merit_order_converters(graph)
        unless @must_run_merit_order_converters
          @must_run_merit_order_converters = Etsource::Loader.instance.globals('must_run_merit_order_converters')
          # Fail early:
          @must_run_merit_order_converters.values.flatten.each do |key|
            unless graph.converter(key)
              raise "Qernel::Graph#merit_order: no converter found for #{key.inspect}. Update datasets/_globals/must_run_merit_order_converters.yml"
            end
          end
        end
        @must_run_merit_order_converters
      end

      #######
      private
      #######

      # Peak power of electricity for all final demand converters..
      def graph_peak_power
        @graph.group_converters(:final_demand_electricity).map{|c| c.query.mw_power }.compact.sum
      end

      # Adjust the load curve (column 0) by subtracting the loads of the must-run converters
      # defined in must_run_merit_order_converters.yml
      # It uses the tabular data from datasets/_globals/merit_order.csv
      #
      # It uses the *merit_order_table*
      #
      #      normalized,  column_1, column_2, column_3, column_4, column_5, column_6, column_7
      #     [ 0.6255066, [0.6186073, 0.0000000, 1.0000000, 0.0002222, 0.0000000, 0.0000000, 0.0000000]],
      #     [ 0.5601907, [0.6186073, 0.0000000, 1.0000000, 0.0001867, 0.0000000, 0.0000000, 0.0000000]],
      #     ...
      #
      # and the merit_order_must_run_loads. The 7 numbers sum loads for every group in must_run_merit_order_converters.yml
      #
      #                   column_1, column_2, column_3, column_4, column_5, column_6, column_7
      #     [             1000,      1500,      8000,     1000,       2000,    300000,   10000]
      #
      # It returns an array of the load profiles, adjusted by subtracting the must-run loads.
      #
      #    [ (0.6255066 * peak_power - ( 0.618 * 1000 + 0.000 * 1500 + 1.000 * 8000 + 0.002 * 1000 ...))]
      #    [ (0.5601907 * peak_power - ( 0.618 * 1000 + 0.000 * 1500 + 1.000 * 8000 + 0.0018 * 1000 ...))]
      #
      def residual_load_profiles # Excel N
        loads      = merit_order_must_run_loads
        peak_power = graph_peak_power

        merit_order_table.map do |normalized_load, wewp|
          load = peak_power * normalized_load

          # take one column from the table and multiply it with the loads
          # defined in the must_run_merit_order_converters.yml
          wewp_x_loads = wewp.zip(loads) # [1,2].zip([3,4]) => [[1,3],[2,4]]
          wewp_x_loads.map!{|wewp, load| wewp * load }

          [0, load - wewp_x_loads.sum].max
        end
      end

      # Returns the summed load for the must-run converters defined in must_run_merit_order_converters.yml.
      #
      # Returns an array of sums for every column_X group, like this:
      #
      # [
      #    247.3,    # [23.2, 211.1, 23.0].sum derived from the column_1: ... converters.
      #    100.1     # [50, 50.1].sum derived from the column_1: ... converters.
      # ]
      #
      def merit_order_must_run_loads
        must_run_merit_order_converters.map do |_ignore_column, converter_keys|
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
      # The merit_order.csv has to be in sync with must_run_merit_order_converters.yml
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


