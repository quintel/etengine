module Qernel::Plugins
  # A plugin which provides access to useful Merit-related calculations, such
  # as loss-of-load and demand curves, without having to fully-run the Merit
  # order itself.
  class SimpleMeritOrder
    include Plugin

    # Simple-mode does not need a full-run, and profiles for must-runs will
    # suffice.
    PARTICIPANT_TYPES = [ :must_run, :volatile ].freeze

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

    def adapters
      return @adapters if @adapters

      @adapters = {}

      self.class::PARTICIPANT_TYPES.each do |type|
        models = converters(type)
        models = sort_flexibles(models) if type == :flex

        models.each do |converter|
          @adapters[converter.key] =
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
        key:               :total_demand,
        load_profile:      dataset.load_profile(:total_demand),
        total_consumption: total_demand
      ))
    end

    #######
    private
    #######

    # Public: Returns the Atlas dataset for the current graph region.
    def dataset
      @dataset ||= Atlas::Dataset.find(@graph.area.area_code)
    end

    # Internal: The total electricity demand, joules, across the graph.
    #
    # Returns a float.
    def total_demand
      0.0
    end

    # Internal: Returns an array of converters which are of the requested merit
    # order +type+ (defined in PRODUCER_TYPES).
    #
    # Returns an array.
    def converters(type)
      (Etsource::MeritOrder.new.import[type.to_s] || {}).map do |key, profile|
        converter = @graph.converter(key)
        converter.converter_api.load_profile_key = profile

        converter
      end
    end

    # Internal: Fetches the adapter matching the given participant `key`.
    #
    # Returns a Plugins::Merit::Adapter or nil.
    def adapter(key)
      adapters[key]
    end

    # Internal: Iterates through each adapter.
    #
    # Returns nothing.
    def each_adapter
      adapters.each { |_, adapter| yield(adapter) }
    end

    # Internal: Given the flexible merit order participant converters, sorts
    # them to match to FlexibilityOrder assigned to the current scenario.
    #
    # Returns an array of Qernel::Converter.
    def sort_flexibles(converters)
      order = @graph.flexibility_order.map(&:to_sym)

      converters.sort_by do |conv|
        order.index(conv.dataset_get(:merit_order).group) || Float::INFINITY
      end
    end
  end # SimpleMeritOrder
end # Qernel::Plugins
