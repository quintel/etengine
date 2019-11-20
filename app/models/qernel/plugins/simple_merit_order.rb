module Qernel::Plugins
  # A plugin which provides access to useful Merit-related calculations, such
  # as loss-of-load and demand curves, without having to fully-run the Merit
  # order itself.
  class SimpleMeritOrder
    include Plugin

    # Public: The SimpleMeritOrder plugin is enabled only on future graphs, and
    # only when the "full" Merit order has not been requested.
    def self.enabled?(graph)
      graph.present? || ! graph.area.use_merit_order_demands
    end

    # Public: A unique name to represent the plugin.
    #
    # Returns a symbol.
    def self.plugin_name
      :merit
    end

    def initialize(graph, context = nil)
      super(graph)

      @context =
        context || Qernel::MeritFacade::Context.new(
          self, graph, :electricity, :merit_order
        )
    end

    def curves
      @curves ||= Qernel::MeritFacade::Curves.new(@graph, household_heat)
    end

    # Simple-mode does not need a full-run, and profiles for must-runs will
    # suffice.
    #
    # Returns an array of participant types. Each element is either a Symbol,
    # specifying that all participants of the matching type should be included,
    # or a 2-element array when limiting by subtype.
    #
    # For example:
    #
    #   # Specifies to include :producers whose subtype is :must_run and all
    #   # consumers.
    #   [%i[producer must_run], :consumer]
    #
    def participant_types
      [%i[producer must_run], %i[producer volatile], :consumer].freeze
    end

    def adapters
      return @adapters if @adapters

      @adapters = {}

      participant_types.each do |(type, subtype)|
        models = converters(type, subtype)
        models = sort_flexibles(models) if type == :flex

        models.each do |converter|
          @adapters[converter.key] ||=
            Qernel::MeritFacade::Adapter.adapter_for(converter, @context)
        end
      end

      @adapters
    end

    # Public: Returns the Merit Order instance. The simple version of the M/O
    # plugin does not initialize the Merit::Order until it is required.
    #
    # Returns a Merit::Order.
    def order
      setup unless @order
      @order
    end

    # Internal: Sets up the Merit::Order. Depending on whether the end-user
    # wants full merit order demands, we will either set up a "light" version
    # which contains only enough information to perform "helper" calculations
    # (such as loss-of-load).
    #
    # If the user wants to include the Merit Order in their graph, we have to
    # supply additional information so that we can determine cost and
    # profitability.
    def setup
      @order = Merit::Order.new

      each_adapter do |adapter|
        # We have to trigger "participant" so that values may be injected after
        # the calculation, even if the participant isn't used in Merit.
        participant = adapter.participant

        @order.add(participant) if adapter.installed?
      end

      @order.add(Merit::User.create(
        key: :total_demand,
        load_curve: total_demand_curve
      ))
    end

    # Internal: Iterates through each adapter.
    #
    # Returns nothing.
    def each_adapter
      return enum_for(:each_adapter) unless block_given?
      adapters.each { |_, adapter| yield(adapter) }
    end

    #######
    private
    #######

    # Internal: A curve describing all demand which should be fulfilled by the
    # merit order.
    #
    # Returns a Merit::Curve
    def total_demand_curve
      @context.dataset.load_profile(:total_demand) * total_demand
    end

    # Internal: The total electricity demand, joules, across the graph.
    #
    # Returns a float.
    def total_demand
      # Remove from total demand the demand of any producer which is modelled as
      # a separate Merit participant.
      individual_demands = each_adapter.sum do |adapter|
        if adapter.config.type == :consumer
          adapter.input_of_carrier
        else
          0.0
        end
      end

      # TODO Do we need to subtract the hot water and space heating demand?
      # Aren't these individual demands now?
      demand = @graph.graph_query.total_demand_for_electricity -
        individual_demands -
        curves.demand_value(:households_hot_water) -
        curves.demand_value(:space_heating) -
        curves.demand_value(:buildings_space_heating)

      demand.negative? ? 0.0 : demand
    end

    # Internal: Returns an array of converters which are of the requested merit
    # order +type+ (defined in PRODUCER_TYPES).
    #
    # Returns an array.
    def converters(type, subtype)
      type_data = Etsource::MeritOrder.new.import_electricity[type.to_s]

      (type_data || {}).map do |key, profile|
        converter = @graph.converter(key)

        if !subtype.nil? && @context.node_config(converter).subtype != subtype
          next
        end

        converter.converter_api.load_profile_key = profile

        converter
      end.compact
    end

    # Internal: Fetches the adapter matching the given participant `key`.
    #
    # Returns a MeritFacade::Adapter or nil.
    def adapter(key)
      adapters[key]
    end

    # Internal: Given the flexible merit order participant converters, sorts
    # them to match to FlexibilityOrder assigned to the current scenario.
    #
    # Returns an array of Qernel::Converter.
    def sort_flexibles(converters)
      order = @graph.flexibility_order.map(&:to_sym)

      converters.sort_by do |conv|
        order.index(@context.node_config(conv).group) || Float::INFINITY
      end
    end

    def household_heat
      Qernel::MeritFacade::SimpleHouseholdHeat.new(
        @graph,
        Causality::CurveSet.for_area(@graph.area, 'weather', 'default')
      )
    end
  end # SimpleMeritOrder
end # Qernel::Plugins
