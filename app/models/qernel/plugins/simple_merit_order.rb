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
          self,
          graph,
          :electricity,
          :merit_order,
          Qernel::MeritFacade::MarginalCostSorter.new
        )
    end

    def curves
      @curves ||= Qernel::MeritFacade::Curves.new(
        @graph,
        @context,
        household_heat,
        rotate: Qernel::Plugins::Causality::CURVE_ROTATE
      )
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
        nodes(type, subtype).each do |node|
          @adapters[node.key] ||= Qernel::MeritFacade::Adapter.adapter_for(node, @context)
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
        next if adapter.config.group.to_s.start_with?('self')

        # We have to trigger "participant" so that values may be injected after
        # the calculation, even if the participant isn't used in Merit.
        participant = adapter.participant

        @order.add(participant) if adapter.installed?
      end
    end

    def setup_dynamic
      each_adapter do |adapter|
        next unless adapter.config.group.to_s.start_with?('self')

        participant = adapter.participant
        @order.add(participant) if adapter.installed?
      end
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

    # Internal: Returns an array of nodes which are of the requested merit
    # order +type+ (defined in PRODUCER_TYPES).
    #
    # Returns an array.
    def nodes(type, subtype)
      type_data = etsource_data[type.to_s]

      nodes = (type_data || {}).map do |key, profile|
        node = @graph.node(key)

        if !subtype.nil? && @context.node_config(node).subtype != subtype
          next
        end

        node.node_api.load_profile_key = profile

        node
      end.compact

      sort_nodes(type, nodes)
    end

    # Internal: Fetches the adapter matching the given participant `key`.
    #
    # Returns a MeritFacade::Adapter or nil.
    def adapter(key)
      adapters[key]
    end

    # Internal: Given the flexible merit order participant nodes, sorts
    # them to match to FlexibilityOrder assigned to the current scenario.
    #
    # Returns an array of Qernel::Node.
    def sort_nodes(type, nodes)
      return nodes unless type == :flex

      order = @graph.flexibility_order.map(&:to_sym)
      index = -1

      nodes.sort_by do |conv|
        [
          order.index(@context.node_config(conv).group) || Float::INFINITY,
          index += 1 # Ensure stable sort.
        ]
      end
    end

    def household_heat
      Qernel::MeritFacade::SimpleHouseholdHeat.new(
        @graph,
        Qernel::Causality::CurveSet.for_area(@graph.area, 'weather', 'default')
      )
    end

    def etsource_data
      Etsource::MeritOrder.new.import_electricity
    end
  end # SimpleMeritOrder
end # Qernel::Plugins
