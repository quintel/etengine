module Qernel::Plugins
  # CalculationBreakpoints break the calculation into multiple steps.
  # Inbetween the steps code can be run to update demands.
  #
  # E.g.
  #
  #   [ foo: nil ] <--- [ nok: nil ]
  #
  #   [ bar: 100 ] <--- [ baz: nil]
  #
  # The only known converter is bar. The demand of foo is defined to be 50% of
  # 'baz'. Running the calculation, would update baz demand to 100 but foo,
  # nok remain nil.
  #
  # To fix this we define the breakpoint :update_foo and a function that runs
  # after the initial calculation.
  #
  #
  #
  #
  # CalculationBreakpoints requires the #calculation_loop method
  #
  #
  module CalculationBreakpoints
    extend ActiveSupport::Concern

    def breakpoints
      @breakpoints ||= {}
    end

    def setup_breakpoints
      breakpoints.values.each(&:setup)
    end

    def next_breakpoint
      breakpoints.delete(breakpoints.keys.first)
    end

    # Are we past the given breakpoint?
    #
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
        !breakpoints.has_key?(breakpoint)
      end
    end

  end
end
