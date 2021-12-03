module Qernel
  # Provides a calculation of electricity load on different layers (typically
  # LV, MV, and HV) including an analysis of the peak load of each layers.
  module Closud
    CONSUMER_TYPES = Set.new(%i[consumer flex])
    PRODUCER_TYPES = Set.new(%i[producer flex])

    module_function

    # Defines participant keys and the network level for participants which do
    # not exist in ETSource.
    PARTICIPANT_LEVELS = {
      fever_hot_water: :lv,
      fever_space_heating: :lv,
      ev_demand: :lv
    }

    # Public: Builds a Closud network based on the `graph`.
    #
    # Returns an OpenStruct which responds to "lv", "mv", and "hv".
    def build(graph)
      layers = OpenStruct.new
      previous = nil
      participants = partition_participants(graph)

      Etsource::Config.electricity_network.each do |layer_config|
        name = layer_config[:name]

        previous = layers[name] = Layer.new(
          base: previous,
          peak: Peak.const_get(layer_config[:peak]),
          **participants[name]
        )
      end

      layers
    end

    # Internal: Takes a graph and returns a hash describing the producers and
    # consumers in each layer.
    #
    # For example:
    #
    #   partition_participants(graph)
    #   # => {
    #   #      lv: { consumers: [...], producers: [...], flexibles: [...] },
    #   #      mv: { consumers: [...], producers: [...], flexibles: [...] },
    #   #      hv: { consumers: [...], producers: [...], flexibles: [...] }
    #   #    }
    #
    def partition_participants(graph)
      by_level = Hash.new do |h, k|
        h[k] = { consumers: [], producers: [], flexibles: [] }
      end

      adapters = graph.plugin(:merit).adapters.values

      adapters.each do |adapter|
        node = adapter.node.query
        level = adapter.config.level || :hv

        if CONSUMER_TYPES.include?(adapter.config.type)
          by_level[level][:consumers].push(Merit::Curve.new(node.query.electricity_input_curve))
        end

        if PRODUCER_TYPES.include?(adapter.config.type)
          by_level[level][:producers].push(Merit::Curve.new(node.query.electricity_output_curve))
        end
      end

      by_level
    end

    private_class_method :partition_participants
  end
end
