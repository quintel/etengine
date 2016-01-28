module Qernel::Plugins
  # Sets up and fully-calculates the Merit order. After the graph has been
  # calculated, the graph demand is supplied to the Merit gem to determine how
  # to fairly assign loads depending on cost.
  #
  # After the merit order has been calculated, it's producer loads are assigned
  # back to the graph, and the graph will be recalculated.
  class MeritOrder < SimpleMeritOrder
    # A list of types of merit order producers to be supplied to the M/O.
    PRODUCER_TYPES = [:must_run, :volatile, :dispatchable, :flex].freeze

    before :first_calculation, :clone_dataset
    after  :first_calculation, :setup
    after  :first_calculation, :run
    before :recalculation,     :inject

    # Public: The SimpleMeritOrder plugin is enabled only on future graphs, and
    # only when the "full" Merit order has been requested (otherwise
    # SimpleMeritOrder will be used instead).
    def self.enabled?(graph)
      graph.future? && graph.dataset_get(:use_merit_order_demands).to_i == 1
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

    # Internal: Given a Merit order participant +type+ and the associated
    # Converter, +conv+, from the graph, returns a hash of attributes required
    # to set up the Participant object in the Merit order.
    #
    # Adds a couple of additional attributes required to calculate costs and
    # profitability.
    #
    # Returns a hash.
    def producer_attributes(type, conv)
      attributes = super

      unless type == :flex
        marginal_cost = conv.variable_costs_per(:mwh_electricity)

        attributes[:marginal_costs] =
          (marginal_cost && marginal_cost.nan?) ? Float::INFINITY : marginal_cost

        attributes[:fixed_costs_per_unit] =
          conv.send(:fixed_costs)

        attributes[:fixed_om_costs_per_unit] =
          conv.send(:fixed_operation_and_maintenance_costs_per_year)
      end

      attributes
    end

    def flex_attributes(conv)
      subtype = conv.load_profile_key.to_sym

      attributes = super

      if conv.dataset_get(:storage)
        # Non-storage flexible technologies do not have a volume.
        attributes[:volume_per_unit] =
          conv.dataset_get(:storage).volume / 1_000_000 # Wh to Mwh
      end

      # Default is to multiply the input capacity by the electricity output
      # conversion. This doesn't work, because the flex converters have a
      # dependant electricity link and the conversion will be zero the first
      # time the graph is calculated.
      attributes[:output_capacity_per_unit] = conv.input_capacity

      # Default for P2P is 0.0?
      attributes[:availability] = 1.0

      # TODO Refactor into a separate class.
      #
      # e.g. FlexAttributes.for(converter)
      if subtype == :power_to_gas
        attributes[:volume_per_unit] = Float::INFINITY
      end

      attributes
    end

    # Internal: Takes loads and costs from the calculated Merit order, and
    # installs them on the appropriate converters in the graph. The updated
    # values will be used in the recalculated graph.
    #
    # Returns nothing.
    def inject_values!
      dispatchables = @order.participants
        .dispatchables.sort_by(&:marginal_costs)

      dispatchables.each_with_index do |dispatchable, position|
        next if dispatchable.is_a?(Merit::Flex::Base)

        converter = @graph.converter(dispatchable.key).converter_api

        flh = dispatchable.full_load_hours
        flh = 0.0 if flh.nan? || flh.nil?
        fls = flh * 3600

        converter[:full_load_hours]      = flh
        converter[:full_load_seconds]    = fls
        converter[:marginal_costs]       = dispatchable.marginal_costs
        converter[:number_of_units]      = dispatchable.number_of_units
        converter[:profitability]        = dispatchable.profitability
        converter[:merit_order_position] = position + 1

        converter[:profit_per_mwh_electricity] =
          dispatchable.profit_per_mwh_electricity

        converter.demand =
          fls * converter.input_capacity * dispatchable.number_of_units
      end

      @order.participants.flex.each do |flex|
        converter = @graph.converter(flex.key).converter_api

        flh = flex.full_load_hours
        flh = 0.0 if flh < 0 || flh.nan? || flh.nil?
        fls = flh * 3600

        converter[:full_load_hours]      = flh
        converter[:full_load_seconds]    = fls

        converter.demand =
          fls * converter.input_capacity * flex.number_of_units
      end

      nil
    end
  end # MeritOrder
end # Qernel::Plugins
