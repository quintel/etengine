module Qernel::Plugins
  module CalculationBreakpoints
    extend ActiveSupport::Concern

    included do |klass|
      set_callback :calculate, :before, :initialize_breakpoint
    end

    def initialize_breakpoint
      set_breakpoint(:initial_loop)
    end

    def breakpoints
      @breakpoints ||= {:initial_loop => 0}
    end

    def add_breakpoint(key)
      breakpoints[key] ||= @breakpoints.length
    end

    def continue_after_breakpoint!(past_breakpoint)
      unless breakpoints.include?(past_breakpoint)
        raise "continue_after_breakpoint #{past_breakpoint.inspect} is not in list: #{breakpoints.inspect}"
      end
      set_breakpoint(past_breakpoint)
      calculation_loop(past_breakpoint)
    end

    # current  | given      |
    # ------------------------------
    # initial   | merit     | false
    # initial   | initial   | true
    # initial   | nil       | true
    # merit     | initial   | true
    # merit     | merit     | true
    #
    def past_breakpoint?(breakpoint)
      if breakpoint.nil?
        true # no breakpoint => run always
      else
        breakpoints[breakpoint] <= @current_breakpoint_idx
      end
    end

    def set_breakpoint(key)
      instrument("graph.set_breakpoint: #{key}") do
        @current_breakpoint     = key
        @current_breakpoint_idx = breakpoints[key]
      end
    end

  end
end
