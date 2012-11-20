module Qernel::Plugins
  module MeritOrder
    extend ActiveSupport::Concern

    MERIT_ORDER_BREAKPOINT = :injected_merit_order

    included do |klass|
      set_callback :calculate, :before, :add_merit_order_breakpoint
      set_callback :calculate, :after,  :calculate_merit_order_if_no_breakpoint
    end

    def add_merit_order_breakpoint
      if use_merit_order_demands?
        brk = MeritOrderBreakpoint.new(self)
        add_breakpoint(brk)
      end
    end

    # some gqueries expect the merit_order_start and end, let's set them to
    # 0 if MO is disabled
    #
    def calculate_merit_order_if_no_breakpoint
      unless use_merit_order_demands?
        MeritOrderBreakpoint.new(self).mock_merit_order
      end
    end

    def use_merit_order_demands?
      self[:use_merit_order_demands].to_i == 1
    end

    # -- internals -----------------------------------------------------------

    # These methods could be moved to the MO breakpoint class
    #

    # Select dispatchable merit order converters
    #
    def dispatchable_merit_order_converters
      @dispatchable_converters ||= begin
        merit_order_data['dispatchable'].keys.map do |k|
          graph.converter(k.to_sym)
        end.compact
      end
    rescue Exception => e
      raise "Error loading dispatchable converters: #{e.message}"
    end

    # memoizes the etsource-based merit order hash
    #
    def merit_order_data
      @merit_order_data ||= Etsource::MeritOrder.new.import
    end

    # Demand of electricity for all final demand converters..
    def graph_electricity_demand
      converter = graph.converter(:energy_power_hv_network_electricity)
      conversion_loss        = converter.output(:loss).conversion
      conversion_electricity = converter.output(:electricity).conversion
      transformer_demand     = graph.converter(:energy_power_transformer_mv_hv_electricity).demand

      total_demand = graph.group_converters(:final_demand_electricity).map(&:demand).compact.sum
      total_demand + transformer_demand * conversion_loss / conversion_electricity
    end


  end # MeritOrder
end


