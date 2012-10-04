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

    def calculated?
      calculated == true
    end

    # Calculates the Graph.
    #
    # = Algorithm
    #
    # 1. Take first converter that is "ready for calculation" (see {Qernel::Converter#ready?}) from the converter stack
    # 2. Calculate the converter (see: {Qernel::Converter#calculate})
    # 3. Remove converter from stack and move it to {#finished_converters}
    # 5. => (continue at 1. until stack is empty)
    # 6. recalculate link shares of output_links (see: {Qernel::Link#update_share})
    #
    def calculate(options = {})
      run_callbacks :calculate do
        return if calculated?

        setup_breakpoints

        instrument("gql.performance.calculate") do
          # FIFO stack of all the converters. Converters are removed from the stack after calculation.
          @converter_stack = converters.clone
          @finished_converters = []

          calculation_loop # the initial loop

          while breakpoint = next_breakpoint
            breakpoint.run
            breakpoint.before_calculation_loop if breakpoint.respond_to?(:before_calculation_loop)
            calculation_loop
            breakpoint.after_calculation_loop  if breakpoint.respond_to?(:after_calculation_loop)
          end

          update_link_shares
        end
      end
      calculated = true
    end

    # A calculation_loop is one cycle of calculating converters until there is
    # no converter left to calculate (no converters is #ready? anymore). This
    # can mean that the calculation is finished or that we need to run a
    # "plugin" (e.g. merit order). The plugin most likely will update some
    # converter demands, what "unlocks" more converters and the calculation can
    # continue.
    #
    def calculation_loop
      while index = @converter_stack.index(&:ready?)
        converter = @converter_stack[index]
        converter.calculate
        @finished_converters << @converter_stack.delete_at(index)
      end
    end

    # Hash of breakpoints. Breakpoint#key is the key of the hash.
    #
    def breakpoints
      @breakpoints ||= {}
    end

    def add_breakpoint(brk)
      unless [:pre_condition_met?, :run, :key].all?{|method| brk.respond_to?(method) }
        raise "breakpoints must implement #pre_condition_met?, #run, #key"
      end
      breakpoints[brk.key] = brk
    end

    def setup_breakpoints
      breakpoints.values.each(&:setup)
    end

    def next_breakpoint
      if brk = breakpoints.values.detect(&:pre_condition_met?)
        breakpoints.delete(brk.key)
        brk
      end
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
    def breakpoint_reached?(breakpoint)
      if breakpoint.nil?
        true # no breakpoint => run always
      else
        !breakpoints.has_key?(breakpoint)
      end
    end

  end
end
