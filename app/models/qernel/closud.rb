module Qernel
  # Provides a calculation of electricity load on different layers (typically
  # LV, MV, and HV) including an analysis of the peak load of each layers.
  module Closud
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
    private_class_method def partition_participants(graph)
      participants = graph.plugin(:merit).order.participants

      by_level = Hash.new do |h, k|
        h[k] = { consumers: [], producers: [], flexibles: [] }
      end

      participants.each do |part|
        node = graph.node(part.key)

        if node
          config = node.merit_order
          level = config.level
          type = closud_type(config.type)

          next if level == :omit
        else
          level = PARTICIPANT_LEVELS[part.key] || :hv
          type = :consumers
        end

        by_level[level][type].push(part.load_curve)
      end

      by_level
    end

    # Internal: Converts the merit config type to the appropriate Closud type.
    private def closud_type(part_type)
      case part_type
      when :consumer then :consumers
      when :flex     then :flexibles
      else                :producers
      end
    end
  end
end
