module Qernel::Plugins
  # Sets up and fully-calculates the Merit order. After the graph has been
  # calculated, the graph demand is supplied to the Merit gem to determine how
  # to fairly assign loads depending on cost.
  #
  # After the merit order has been calculated, it's producer loads are assigned
  # back to the graph, and the graph will be recalculated.
  class MeritOrder < SimpleMeritOrder
    # A list of types of merit order producers to be supplied to the M/O.
    PARTICIPANT_TYPES = [:must_run, :volatile, :dispatchable, :flex].freeze

    before :first_calculation, :clone_dataset
    after  :first_calculation, :setup
    after  :first_calculation, :run
    before :recalculation,     :inject

    # Public: The MeritOrder plugin is enabled only on future graphs, and only
    # when the "full" Merit order has been requested (otherwise SimpleMeritOrder
    # will be used instead).
    def self.enabled?(graph)
      graph.future? && graph.area.use_merit_order_demands
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

    # Internal: Takes the values from the "run" step and sets them on the
    # appropriate converters in the graph.
    def inject
      @order.calculate

      # Detaching the dataset clears the goals. This would ordinarily be correct
      # behaviour, but we need to preserve them for the second calculation.
      goals = @graph.goals
      @graph.detach_dataset!

      @graph.dataset = @original_dataset
      @graph.goals   = goals

      # Any subsequent calculations (one of which) must have the merit order
      # demands injected into the graph.
      inject_values!
    end

    #######
    private
    #######

    # Internal: The total electricity demand, joules, across the graph.
    #
    # Returns a float.
    def total_demand
      @graph.graph_query.total_demand_for_electricity
    end

    # Internal: Takes loads and costs from the calculated Merit order, and
    # installs them on the appropriate converters in the graph. The updated
    # values will be used in the recalculated graph.
    #
    # Returns nothing.
    def inject_values!
      each_adapter(&:inject!)
      set_dispatchable_positions!
    end

    # Internal: Sets the position of each dispatchable in the merit order -
    # according to their marginal cost - so that this may be communicated to
    # other applications.
    #
    # Returns nothing.
    def set_dispatchable_positions!
      dispatchables = @order.participants.dispatchables.reject do |participant|
        # Flexible technologies are classed as dispatchable but should not be
        # assigned a position.
        adapter(participant.key).config.type != :dispatchable
      end

      dispatchables.each.with_index do |participant, position|
        adapter(participant.key).converter[:merit_order_position] = position + 1
      end
    end
  end # MeritOrder
end # Qernel::Plugins
