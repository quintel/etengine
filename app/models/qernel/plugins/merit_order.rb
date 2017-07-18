module Qernel::Plugins
  # Sets up and fully-calculates the Merit order. After the graph has been
  # calculated, the graph demand is supplied to the Merit gem to determine how
  # to fairly assign loads depending on cost.
  #
  # After the merit order has been calculated, it's producer loads are assigned
  # back to the graph, and the graph will be recalculated.
  class MeritOrder < SimpleMeritOrder
    # Public: The MeritOrder plugin is enabled only on future graphs, and only
    # when the "full" Merit order has been requested (otherwise SimpleMeritOrder
    # will be used instead).
    def self.enabled?(graph)
      graph.future? && graph.area.use_merit_order_demands
    end

    # A list of types of merit order producers to be supplied to the M/O.
    def participant_types
      [:must_run, :volatile, :dispatchable, :flex].freeze
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

    # Internal: Sets up the Merit::Order.
    #
    # Adds users to the merit order for consumers which need to follow a custom
    # profile.
    def setup
      super

      @order.add(::Merit::User.create(
        key:        :household_hot_water,
        load_curve: curves.household_hot_water_demand
      ))
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

    private

    # Internal: Merit::Curve describing demand.
    def total_demand_curve
      # Hot water demand is added as a separate user so that demand may be
      # altered by P2H.
      @total_demand_curve ||= super + curves.combined
    end

    # Internal: The total electricity demand, joules, across the graph, minus
    # demand from dynamic electricity curves.
    #
    # Returns a float.
    def total_demand
      @graph.graph_query.total_demand_for_electricity -
        # Curves are in mWh; convert back to J.
        (3600.0 * (curves.combined.sum + curves.household_hot_water_demand.sum))
    end

    # Internal: Sets the position of each dispatchable in the merit order -
    # according to their marginal cost - so that this may be communicated to
    # other applications.
    #
    # Returns nothing.
    def set_dispatchable_positions!
      dispatchables = @order.participants.dispatchables.select do |participant|
        # Flexible technologies are classed as dispatchable but should not be
        # assigned a position.
        adapter(participant.key).config.type == :dispatchable
      end

      dispatchables.each.with_index do |participant, position|
        adapter(participant.key).converter[:merit_order_position] = position + 1
      end
    end
  end # MeritOrder
end # Qernel::Plugins
