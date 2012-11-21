module Qernel::Plugins
  module MeritOrder
    extend ActiveSupport::Concern

    MERIT_ORDER_BREAKPOINT = :injected_merit_order

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


