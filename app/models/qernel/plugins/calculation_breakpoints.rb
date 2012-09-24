module Qernel::Plugins
  module CalculationBreakpoints
    extend ActiveSupport::Concern

    BREAKPOINTS = {
      :start       => 0,
      :merit_order => 1,
      :finished    => 2
    }

    included do |klass|
      set_callback :calculate, :before, :initialize_breakpoint
    end

    def initialize_breakpoint
      set_breakpoint(:start)
    end

    def continue_after_breakpoint!(past_breakpoint)
      unless BREAKPOINTS.include?(past_breakpoint)
        raise "continue_after_breakpoint #{past_breakpoint.inspect} is not in list: #{BREAKPOINTS.inspect}"
      end
      set_breakpoint(past_breakpoint)
      calculation_loop
    end

    def set_breakpoint(key)
      @current_breakpoint     = key
      @current_breakpoint_idx = BREAKPOINTS[key]
    end

    # current | given   |
    # -----------------------
    # start   | merit   | false
    # start   | start   | true
    # start   | nil     | true
    # merit   | start   | true
    # merit   | merit   | true
    #
    def past_breakpoint?(breakpoint)
      if breakpoint.nil?
        true
      else
        BREAKPOINTS[breakpoint] <= @current_breakpoint_idx
      end
    end
  end
end
