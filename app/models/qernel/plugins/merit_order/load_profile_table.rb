module Qernel::Plugins
  module MeritOrder
    # LoadProfileTable connects the static load data defined in yml files with the actual
    # demands of the graph.
    #
    # It requires that:
    # - G(final_demand_electricity) have calculated demand (through #mw_power)
    # - must_run_merit_order_converters.yml converters have calculated demand
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
      # We basically group the array of load profiles into n bins (n defined by PRECISION).
      #
      #   * x: the max of residual_load_profiles divided by the bin-size
      #   (e.g. for N = 10 and max_load = 4000: 4000 * 0.1 => 400)
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

      # @return a Hash {column_1: ['converter_key_1', 'converter_key_2'], column_2: [...]}
      def must_run_merit_order_converters
        self.class.must_run_merit_order_converters(@graph)
      end

      # @return a Hash {column_1: ['converter_key_1', 'converter_key_2'], column_2: [...]}
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

      def self.must_run_merit_order_converter_objects(graph)
        must_run_merit_order_converters(graph).values.flatten.map do |key|
          graph.converter(key)
        end
      end

      #######
      private
      #######

      # Demand of electricity for all final demand converters..
      def graph_electricity_demand
        @graph.group_converters(:final_demand_electricity).map{|c| c.query.demand }.compact.sum
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
      # and the merit_order_must_run_production. The 7 numbers sum electricity production for every group in must_run_merit_order_converters.yml
      #
      #                   column_1, column_2, column_3, column_4, column_5, column_6, column_7
      #     [             1000,      1500,      8000,     1000,       2000,    300000,   10000]
      #
      # It returns an array of the load profiles, adjusted by subtracting the must-run production.
      #
      #    [ (0.6255066 * peak_power - ( 0.618 * 1000 + 0.000 * 1500 + 1.000 * 8000 + 0.002 * 1000 ...))]
      #    [ (0.5601907 * peak_power - ( 0.618 * 1000 + 0.000 * 1500 + 1.000 * 8000 + 0.0018 * 1000 ...))]
      #
      def residual_load_profiles # Excel N
        loads      = merit_order_must_run_production
        electricity_demand = graph_electricity_demand

        merit_order_table.map do |normalized_load, wewp|
          load = electricity_demand * normalized_load

          # take one column from the table and multiply it with the loads
          # defined in the must_run_merit_order_converters.yml
          wewp_x_loads = wewp.zip(loads) # [1,2].zip([3,4]) => [[1,3],[2,4]]
          wewp_x_loads.map!{|wewp, load| wewp * load }

          [0, load - wewp_x_loads.sum].max
        end
      end

      # THis is for debugging only and can be removed
      #
      def residual_load_profiles_table
        loads              = merit_order_must_run_production
        electricity_demand = graph_electricity_demand

        merit_order_table.map do |normalized_load, wewp|
          load = electricity_demand * normalized_load

          # take one column from the table and multiply it with the loads
          # defined in the must_run_merit_order_converters.yml
          wewp_x_loads = wewp.zip(loads) # [1,2].zip([3,4]) => [[1,3],[2,4]]
          wewp_x_loads.map!{|wewp, load| wewp * load }

          [load, *wewp_x_loads]
        end
      end


      # Returns the summed production for the must-run converters defined in must_run_merit_order_converters.yml.
      #
      # Returns an array of sums for every column_X group, like this:
      #
      # [
      #    247.3,    # [23.2, 211.1, 23.0].sum derived from the column_1: ... converters.
      #    100.1     # [50, 50.1].sum derived from the column_1: ... converters.
      # ]
      #
      def merit_order_must_run_production
        must_run_merit_order_converters.map do |_, converter_keys|
          converter_keys.map do |key|
            converter = @graph.converter(key).query
            begin

              # mw_power is alias to mw_input_capacity
              converter.instance_exec { demand * electricity_output_conversion }
            rescue
              raise "Merit Order: merit_order_must_run_production: Error with converter #{key}: #{debug}"
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
  end
end
