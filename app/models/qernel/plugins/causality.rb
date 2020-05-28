module Qernel::Plugins
  # Graph plugin which coordinates the calculation of time-resolved electricity
  # and heat loads in Merit and Fever.
  class Causality
    include Plugin

    # Rotate curves in step-calculated components (Fever and Merit) so that we
    # start on April 1st, and calculate through to March 31st, instead of
    # January 1st to December 31st.
    CURVE_ROTATE = 2160

    before :first_calculation, :clone_dataset
    after  :first_calculation, :setup
    after  :first_calculation, :run
    before :recalculation,     :inject
    after  :recalculation,     :inject_reconciliation

    attr_reader :merit
    attr_reader :fever
    attr_reader :heat_network

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
      @merit = Qernel::Causality::Electricity.new(graph)
      @fever = Qernel::FeverFacade::Manager.new(graph)
      @heat_network = Qernel::Causality::HeatNetwork.new(graph)
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

      @merit.setup_dynamic
      @heat_network.setup_dynamic
    end

    def inject
      merit_calc = Merit::StepwiseCalculator.new.calculate(@merit.order)

      heat_network_calc = Merit::StepwiseCalculator.new.calculate(
        @heat_network.order
      )

      8760.times do |frame|
        @fever.calculate_frame(frame)
        heat_network_calc.call(frame)
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
      @fever.inject_values!
      @heat_network.inject_values!
      @merit.inject_values!
    end

    # Internal: Calculate and inject "Reconciliation" curves.
    #
    # This is performed after the recalculation of the graph, ensuring that and
    # changes in demand caused in `inject` are correctly accounted for.
    def inject_reconciliation
      @reconciliation = Qernel::Causality::ReconciliationWrapper.new(@graph)
      @reconciliation.setup

      @reconciliation.inject_values!
    end
  end
end
