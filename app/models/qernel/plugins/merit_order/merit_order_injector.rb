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
      end

      def run
        if @graph.use_merit_order_demands? && graph.future?
          setup_items
          calculate_merit_order
        end
      end

      # TODO: make clear or refactor that FLHs and number of units is also
      # updated. (and that we add an index number too)
      def inject_updated_demand
        position_index = 1
        @m.dispatchables.each do |dispatchable|
          converter = graph.converter(dispatchable.key).converter_api

          flh = dispatchable.full_load_hours
          flh = 0.0 if flh.nan? || flh.nil?
          fls = flh * 3600

          converter[:full_load_hours]   = flh
          converter[:full_load_seconds] = fls
          converter[:marginal_costs]    = dispatchable.marginal_costs
          converter[:number_of_units]   = dispatchable.number_of_units
          converter[:profitable]   = dispatchable.profitability == :profitable

          capacity_production = dispatchable.output_capacity_per_unit *
                                dispatchable.number_of_units rescue nil

          if capacity_production.zero? || capacity_production.nil?
            position = -1
          else
            position = position_index
            position_index += 1
          end
          converter[:merit_order_position] = position

          converter.demand = fls *
                             converter.effective_input_capacity *
                             dispatchable.number_of_units
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
            output_capacity_per_unit: c.electricity_output_conversion * c.effective_input_capacity,
            number_of_units: c.number_of_units,
            availability: c.availability,
            fixed_costs_per_unit: c.send(:fixed_costs),
            fixed_om_costs_per_unit: c.send(:fixed_operation_and_maintenance_costs_per_year)
          }
          if type == :must_run || type == :volatile
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

    end # class MeritOrderInjector
  end # module MeritOrder
end # module Qernel::Plugins
