module Qernel::Plugins
  module MeritOrder
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
    #   SUM = graph_electricity_demand             SUM(mw_power * electr_output_conversion * availability)
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
    class MeritOrderBreakpoint
      include Instrumentable

      attr_reader :key, :graph, :items

      def initialize(graph)
        @graph = graph
        @key   = Qernel::Plugins::MeritOrder::MERIT_ORDER_BREAKPOINT
      end

      # Required by CalculationBreakpoint
      #
      # Assign breakpoint merit_order to dispatchable MO converters. So that the calculation
      # does not calculate demand for them, and we can instead update the demands from the
      # MO calculation. The updated demand will then backpropagate to the grid.
      #
      def setup
        dispatchable_converters_for_merit_order.each do |converter_api|
          converter_api.converter.breakpoint = MERIT_ORDER_BREAKPOINT
        end
      end

      # Required by CalculationBreakpoint
      #
      def run
        setup_items
        calculate_merit_order
        calculate_full_load_hours
        if @graph.use_merit_order_demands?
          inject_updated_demand if @graph.future?
        end
      end

      # --- Merit Order Gem --------------------------------------------------

      def setup_items
        @m = Merit::Order.new
        DebugLogger.debug 'building MO items'
        add_volatile_producers
      end

      def add_volatile_producers
        DebugLogger.debug "Volatile: #{volatile_producers}"
        volatile_producers.each do |p|
          c = p.converter_api
          begin
            producer = Merit::VolatileProducer.new(
              key: p.key,
              marginal_costs: c.merit_order_variable_costs_per(:mwh_electricity),
              effective_output_capacity: c.electricity_output_conversion * c.effective_input_capacity,
              number_of_units: c.number_of_units,
              availability: c.availability,
              fixed_costs: c.send(:fixed_costs),
              load_profile_key: c.load_profile_key,
              full_load_hours: c.full_load_hours
            )
            @m.add producer
          rescue Exception => e
            raise "Merit order: error adding producer #{p.key}: #{e.message}"
          end
        end
      end

      # ---- Converters ------------------------------------------------------------

      # Select dispatchable merit order converters
      def dispatchable_merit_order_converters
        @graph.dispatchable_merit_order_converters
      end

      def volatile_producers
        @volatile_producers ||= begin
          converters = []
          @graph.merit_order_data['volatile'].each_pair do |key, profile_key|
            c = graph.converter(key)
            c.converter_api.load_profile_key = profile_key
            converters.push c
          end
          converters
        end
      rescue Exception => e
        raise "Merit order: error fetching volatile producers: #{e.message}"
      end





      # Converters to include in the sorting: G(merit_order_converters)
      # returns array of converter objects
      def dispatchable_converters_for_merit_order
        dispatchable_merit_order_converters.map(&:query).tap do |arr|
          unless Rails.env.test?
            raise "MeritOrder: no converters in group: merit_order_converters. Update ETsource." if arr.empty?
          end
        end
      end

      # Sort dispatschable converters by their total variable costs. Cheaper power plants should be used first.
      # returns (sorted) array of converter objects
      def converters_by_total_variable_cost
        dispatchable_converters_for_merit_order.sort_by do |c|
          # Sort by the variable costs of electricity output per MWh
          if Rails.env.test?
            c.merit_order_variable_costs_per(:mwh_electricity) rescue nil
          else
            c.merit_order_variable_costs_per(:mwh_electricity)
          end
        end
      end

      # ---- inject_updated_demand ------------------------------------------------------------

      def inject_updated_demand
        converters_by_total_variable_cost.each do |converter|
          converter[:full_load_hours]   = converter.merit_order_full_load_hours
          converter[:full_load_seconds] = converter.merit_order_full_load_hours * 3600
          converter[:capacity_factor]   = converter.merit_order_capacity_factor

          # DEBT: check this better!
          new_demand = converter.full_load_seconds * converter.effective_input_capacity * converter.number_of_units

          # do not overwrite demand with nil
          converter.demand = new_demand if new_demand
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

          @graph.dataset_set(:calculate_merit_order_finished, true)
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
        return unless @graph.area.area_code == 'nl'
        return if dispatchable_merit_order_converters.empty?

        if @graph.dataset_get(:calculate_merit_order_finished) != true
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

        area_size         = profile_curve.area(merit_order_start, merit_order_end)
        merit_span        = [merit_order_end - merit_order_start, 0.0].max
        availability      = converter.availability

        capacity_factor   = [availability * (area_size / merit_span).rescue_nan, availability].min
      end

      # Create a CurveArea with the residual-ldc coordinates.
      # SB: I resist the temptation to make an instance variable out of it, otherwise it'll persist
      # over requests and will cause mischief.
      def residual_load_duration_curve
        coordinates = LoadProfileTable.new(@graph).residual_ldc_coordinates
        CurveArea.new(coordinates)
      end
    end
  end
end