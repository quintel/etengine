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

    def calculate_merit_order_if_no_breakpoint
      unless use_merit_order_demands?
        MeritOrderBreakpoint.new(self).run
      end
    end

    def use_merit_order_demands?
      if self[:use_merit_order_demands].nil?
        false
      else
        self[:use_merit_order_demands].to_i == 1
      end
    end

    # Select dispatchable merit order converters
    def dispatchable_merit_order_converters
      group_converters(:merit_order_converters)
    end

  end # MeritOrder
end


