module Qernel::Plugins
  module MeritOrder
    #
    # Merit Order is influenced among others by sliders:
    # --------------------------
    # * that update number_of_units of plants
    #   => This also overwrites the preset demand of these demands
    # * update costs for energy carriers
    # * other changes to final electricity demand
    #
    # Workflow
    # --------
    # * Run a full calculation loop
    # * Feed the results to the merit order library
    # * Let MO calculate the new FLH and marginal costs
    # * Inject those values in the converters
    # * Run a full calculation loop again
    #
    class MeritOrderInjector
      include Instrumentable

      attr_reader :key, :graph

      def initialize(graph)
        @graph = graph
      end

      def run
        if @graph.use_merit_order_demands? && graph.future?
          setup_items
          calculate_merit_order
          inject_updated_demand
        end
      end

      # --- Merit Order Gem --------------------------------------------------

      def setup_items
        @m = ::Merit::Order.new
        add_volatile_producers
        add_must_run_producers
        add_dispatchable_producers
        add_total_demand
      end

      def add_volatile_producers
        volatile_producers.each do |p|
          c = p.converter_api
          begin
            producer = ::Merit::VolatileProducer.new(
              key: p.key,
              marginal_costs: c.variable_costs_per(:mwh_electricity),
              effective_output_capacity: c.electricity_output_conversion * c.effective_input_capacity,
              number_of_units: c.number_of_units,
              availability: c.availability,
              fixed_costs: c.send(:fixed_costs),
              load_profile_key: c.load_profile_key,
              full_load_hours: c.full_load_hours
            )
            @m.add producer
          rescue Exception => e
            raise "Merit order: error adding volatile producer #{p.key}: #{e.message}"
          end
        end
      end

      def add_must_run_producers
        must_run_producers.each do |p|
          c = p.converter_api
          begin
            producer = ::Merit::MustRunProducer.new(
              key: p.key,
              marginal_costs: c.variable_costs_per(:mwh_electricity),
              effective_output_capacity: c.electricity_output_conversion * c.effective_input_capacity,
              number_of_units: c.number_of_units,
              availability: c.availability,
              fixed_costs: c.send(:fixed_costs),
              load_profile_key: c.load_profile_key,
              full_load_hours: c.full_load_hours
            )
            @m.add producer
          rescue Exception => e
            raise "Merit order: error adding must-run producer #{p.key}: #{e.message}"
          end
        end
      end

      def add_dispatchable_producers
        dispatchable_producers.each do |p|
          c = p.converter_api
          begin
            producer = ::Merit::DispatchableProducer.new(
              key: p.key,
              marginal_costs: c.variable_costs_per(:mwh_electricity),
              effective_output_capacity: c.electricity_output_conversion * c.effective_input_capacity,
              number_of_units: c.number_of_units,
              availability: c.availability,
              fixed_costs: c.send(:fixed_costs)
            )
            @m.add producer
          rescue Exception => e
            raise "Merit order: error adding dispatchable producer #{p.key}: #{e.message}"
          end
        end
      end

      def add_total_demand
        u = ::Merit::User.new(
          key: :total_demand,
          total_consumption: total_electricity_demand
        )
        @m.add u
      rescue Exception => e
        raise "Merit order: error adding total_demand: #{e.message}"
      end

      # ---- Converters ------------------------------------------------------

      # memoizes the etsource-based merit order hash
      #
      def merit_order_data
        @merit_order_data ||= Etsource::MeritOrder.new.import
      end

      # Select dispatchable merit order converters
      def dispatchable_producers
        @dispatchable_converters ||= begin
          merit_order_data['dispatchable'].keys.map do |k|
            graph.converter(k.to_sym)
          end.compact
        end
      rescue Exception => e
        raise "Error loading dispatchable converters: #{e.message}"
      end

      def volatile_producers
        @volatile_producers ||= begin
          converters = []
          merit_order_data['volatile'].each_pair do |key, profile_key|
            c = graph.converter(key)
            c.converter_api.load_profile_key = profile_key
            converters.push c
          end
          converters
        end
      rescue Exception => e
        raise "Merit order: error fetching volatile producers: #{e.message}"
      end

      def must_run_producers
        @must_run_producers ||= begin
          converters = []
          merit_order_data['must_run'].each_pair do |key, profile_key|
            c = graph.converter(key)
            c.converter_api.load_profile_key = profile_key
            converters.push c
          end
          converters
        end
      rescue Exception => e
        raise "Merit order: error fetching must-run producers: #{e.message}"
      end

      # --- stuff we need from the graph -------------------------------------

      # Demand of electricity for all final demand converters..
      def total_electricity_demand
        converter = graph.converter(:energy_power_hv_network_electricity)
        conversion_loss        = converter.output(:loss).conversion
        conversion_electricity = converter.output(:electricity).conversion
        transformer_demand     = graph.converter(:energy_power_transformer_mv_hv_electricity).demand

        total_demand = graph.group_converters(:final_demand_electricity).map(&:demand).compact.sum
        total_demand + transformer_demand * conversion_loss / conversion_electricity
      end

      # ---- inject_updated_demand -------------------------------------------

      def inject_updated_demand
        position_index = 1
        @m.dispatchables.each do |d|
          c = graph.converter(d.key).converter_api

          flh = d.full_load_hours
          flh = 0 if flh.nan?
          c[:full_load_hours]   = flh
          c[:full_load_seconds] = flh * 3600
          c[:marginal_costs]    = d.marginal_costs

          capacity_production = c.installed_production_capacity_in_mw_electricity
          if capacity_production.zero? || capacity_production.nil?
            position = -1
          else
            position = position_index
            position_index += 1
          end
          c[:merit_order_position] = position

          # DEBT: check this better!
          new_demand = c.full_load_seconds * c.effective_input_capacity * c.number_of_units

          # do not overwrite demand with nil
          c.demand = new_demand if new_demand
        end
      end

      # ---- MeritOrder ------------------------------------------------------

      def calculate_merit_order
        return if dispatchable_producers.empty?
        instrument("qernel.merit_order: calculate_merit_order") do
          @m.calculate
          @graph.dataset_set(:calculate_merit_order_finished, true)
        end
      end
    end
  end
end