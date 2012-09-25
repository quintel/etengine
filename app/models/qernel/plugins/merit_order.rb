module Qernel::Plugins
  module MeritOrder
    extend ActiveSupport::Concern

    MERIT_ORDER_BREAKPOINT = :injected_merit_order

    included do |klass|
      set_callback :calculate, :before, :add_merit_order_breakpoint
    end

    def add_merit_order_breakpoint
      if merit_order_enabled?
        brk = MeritOrderBreakpoint.new(self)
        breakpoints[brk.key] = brk
      end
    end

    def merit_order_enabled?
      true
    end

    # Select dispatchable merit order converters
    def dispatchable_merit_order_converters
      group_converters(:merit_order_converters)
    end

  end # MeritOrder
end


