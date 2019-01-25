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

    def initialize(graph)
      super
    end

    def curves
      @curves ||= Qernel::Plugins::Merit::Curves.new(@graph, household_heat)
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
            Qernel::Plugins::Merit::Adapter.adapter_for(
              converter, @graph, dataset
            )
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
      @order = ::Merit::Order.new

      each_adapter do |adapter|
        @order.add(adapter.participant)
      end

      @order.add(::Merit::User.create(
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
      dataset.load_profile(:total_demand) * total_demand
    end

    # Public: Returns the Atlas dataset for the current graph region.
    def dataset
      @dataset ||= Atlas::Dataset.find(@graph.area.area_code)
    end

    # Internal: The total electricity demand, joules, across the graph.
    #
    # Returns a float.
    def total_demand
      # Remove from total demand the demand of any producer which is modelled as
      # a separate Merit participant.
      individual_demands = each_adapter.sum do |adapter|
        if adapter.config.type == :consumer
          adapter.input_of_electricity
        else
          0.0
        end
      end

      # TODO Do we need to subtract the hot water and space heating demand?
      # Aren't these individual demands now?
      demand = @graph.graph_query.total_demand_for_electricity -
        individual_demands -
        curves.demand_value(:hot_water) -
        curves.demand_value(:space_heating) -
        curves.demand_value(:buildings_space_heating)

      demand.negative? ? 0.0 : demand
    end

    # Internal: Returns an array of converters which are of the requested merit
    # order +type+ (defined in PRODUCER_TYPES).
    #
    # Returns an array.
    def converters(type, subtype)
      (Etsource::MeritOrder.new.import[type.to_s] || {}).map do |key, profile|
        converter = @graph.converter(key)

        next if !subtype.nil? && converter.merit_order.subtype != subtype

        converter.converter_api.load_profile_key = profile

        converter
      end.compact
    end

    # Internal: Fetches the adapter matching the given participant `key`.
    #
    # Returns a Plugins::Merit::Adapter or nil.
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
        order.index(conv.merit_order.group) || Float::INFINITY
      end
    end

    def household_heat
      Merit::SimpleHouseholdHeat.new(
        @graph,
        TimeResolve::CurveSet.with_dataset(dataset, 'heat', 'default')
      )
    end
  end # SimpleMeritOrder
end # Qernel::Plugins
