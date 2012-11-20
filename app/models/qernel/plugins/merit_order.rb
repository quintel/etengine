module Qernel::Plugins
  module MeritOrder
    extend ActiveSupport::Concern

    MERIT_ORDER_BREAKPOINT = :injected_merit_order

    included do |klass|
      set_callback :calculate, :before, :add_merit_order_breakpoint
      # Disabled by PZ: is there any reason to run the merit order calculation
      # when MO is off?
      # set_callback :calculate, :after,  :calculate_merit_order_if_no_breakpoint
    end

    def add_merit_order_breakpoint
      if use_merit_order_demands?
        brk = MeritOrderBreakpoint.new(self)
        add_breakpoint(brk)
      end
    end

    def calculate_merit_order_if_no_breakpoint
      unless use_merit_order_demands?
        MeritOrderBreakpoint.new(self).run
      end
    end

    def use_merit_order_demands?
      self[:use_merit_order_demands].to_i == 1
    end

    # Select dispatchable merit order converters
    #
    def dispatchable_merit_order_converters
      @dispatchable_converters ||= begin
        merit_order_data['dispatchable'].keys.map do |k|
          graph.converter(k.to_sym)
        end.compact
      end
    end

    private

    # memoizes the etsource-based merit order hash
    #
    def merit_order_data
      @merit_order_data ||= Etsource::MeritOrder.new.import
    end



  end # MeritOrder
end


