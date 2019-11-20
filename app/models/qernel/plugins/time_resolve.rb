module Qernel::Plugins
  # Graph plugin which coordinates the calculation of time-resolved electricity
  # and heat loads in Merit and Fever.
  class TimeResolve
    include Plugin

    before :first_calculation, :clone_dataset
    after  :first_calculation, :setup
    after  :first_calculation, :run
    before :recalculation,     :inject

    attr_reader :merit
    attr_reader :fever

    # Public: The SimpleMeritOrder plugin is enabled only on future graphs, and
    # only when the "full" Merit order has not been requested.
    def self.enabled?(graph)
      !SimpleMeritOrder.enabled?(graph)
    end

    # Public: A unique name to represent the plugin.
    #
    # Returns a symbol.
    def self.plugin_name
      :time_resolve
    end

    def initialize(graph)
      super
      @merit = Qernel::MeritFacade::Manager.new(graph)
      @fever = Qernel::FeverFacade::Manager.new(graph)
      @heat_network = HeatNetwork.new(graph)
      @reconciliation = ReconciliationWrapper.new(graph)
    end

    # Internal: Sets up the Merit::Order. Clones the graph dataset so that we
    # can reset the graph after the first calculation.
    def clone_dataset
      @original_dataset = DeepClone.clone(@graph.dataset)
    end

    # Internal: After the first graph is calculated, demands are passed into the
    # Merit order to determine in which order to run the plants. The results are
    # stored for future use.
    def run(lifecycle)
      lifecycle.must_recalculate!
    end

    # Internal: Sets up Fever and Merit.
    def setup
      @fever.setup
      @merit.setup
      @heat_network.setup
      @reconciliation.setup
    end

    def inject
      merit_calc = Merit::StepwiseCalculator.new.calculate(@merit.order)

      8760.times do |frame|
        @fever.calculate_frame(frame)
        merit_calc.call(frame)
      end

      # Detaching the dataset clears the goals. This would ordinarily be correct
      # behaviour, but we need to preserve them for the second calculation.
      @graph.retaining_lifecycle do
        goals = @graph.goals
        @graph.detach_dataset!

        @graph.dataset = @original_dataset
        @graph.goals   = goals
      end

      # Any subsequent calculations (one of which) must have the merit order
      # demands injected into the graph.
      @merit.send(:inject_values!)
      @fever.inject_values!

      @heat_network.order.calculate
      @heat_network.send(:inject_values!)

      @reconciliation.inject_values!
    end
  end
end
