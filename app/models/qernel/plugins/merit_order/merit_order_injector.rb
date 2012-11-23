module Qernel::Plugins
  module MeritOrder
    #
    # Merit Order is influenced among others by sliders:
    # --------------------------
    # * that update number_of_units of plants
    #   => This also overwrites the preset demand of these demands
    # * update costs of energy carriers
    # * update costs of technologies
    # * update costs of CO2
    # * changes to final electricity demand
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
        @capacities = {}
      end

      def run
        if @graph.use_merit_order_demands? && graph.future?
          setup_items
          calculate_merit_order
          store_capacities
        end
      end

      def inject_updated_demand
        position_index = 1
        @m.dispatchables.each do |d|
          c = graph.converter(d.key).converter_api

          flh = d.full_load_hours
          flh = 0.0 if flh.nan? || flh.nil?
          c[:full_load_hours]   = flh
          c[:full_load_seconds] = flh * 3600
          c[:marginal_costs]    = d.marginal_costs

          capacity_production = @capacities[c.key]

          if capacity_production.zero? || capacity_production.nil?
            position = -1
          else
            position = position_index
            position_index += 1
          end
          c[:merit_order_position] = position
          c.demand = nil
        end
      end

      #######
      private
      #######

      def setup_items
        @m = ::Merit::Order.new
        add_volatile_producers
        add_must_run_producers
        add_dispatchable_producers
        add_total_demand
      end

      def add_volatile_producers
        volatile_producers.each {|p| add_producer :volatile, p}
      end

      def add_must_run_producers
        must_run_producers.each {|p| add_producer :must_run, p}
      end

      def add_dispatchable_producers
        dispatchable_producers.each {|p| add_producer :dispatchable, p}
      end

      def add_producer(type, p)
        klass = case type
          when :dispatchable then ::Merit::DispatchableProducer
          when :volatile     then ::Merit::VolatileProducer
          when :must_run     then ::Merit::MustRunProducer
        end

        begin
          c = p.converter_api
          attrs = {
            key: p.key,
            marginal_costs: c.variable_costs_per(:mwh_electricity),
            effective_output_capacity: c.electricity_output_conversion * c.effective_input_capacity,
            number_of_units: c.number_of_units,
            availability: c.availability,
            fixed_costs: c.send(:fixed_costs)
          }
          if type == :must_run || type == :volatile_producers
            attrs[:load_profile_key] = c.load_profile_key
            attrs[:full_load_hours]  = c.full_load_hours
          end
          producer = klass.new(attrs)
          @m.add producer
        rescue Exception => e
          raise "Merit order: error adding #{type} #{p.key}: #{e.message}"
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

      # Demand of electricity for all final demand converters..
      def total_electricity_demand
        converter = graph.converter(:energy_power_hv_network_electricity)
        conversion_loss        = converter.output(:loss).conversion
        conversion_electricity = converter.output(:electricity).conversion
        transformer_demand     = graph.converter(:energy_power_transformer_mv_hv_electricity).demand

        total_demand = graph.group_converters(:final_demand_electricity).map(&:demand).compact.sum
        total_demand + transformer_demand * conversion_loss / conversion_electricity
      end


      def calculate_merit_order
        return if dispatchable_producers.empty?
        instrument("qernel.merit_order: calculate_merit_order") do
          @m.calculate
        end
      end

      # Store a copy of each converter's production capacity so that we can
      # later use it to set the merit order positions of each converter.
      def store_capacities
        @m.dispatchables.each do |d|
          @capacities[d.key] = graph.converter(d.key).converter_api.
            installed_production_capacity_in_mw_electricity
        end
      end
    end # class MeritOrderInjector
  end # module MeritOrder
end # module Qernel::Plugins
