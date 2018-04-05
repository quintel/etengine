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

      config.each do |layer_config|
        name = layer_config[:name]

        previous = layers[name] = Layer.new(
          consumers: participants[name][:consumers],
          producers: participants[name][:producers],
          base: previous,
          peak: layer_config[:peak]
        )
      end

      layers
    end

    private_class_method def config
      [ { name: :lv, peak: Peak::Net },
        { name: :mv, peak: Peak::Net },
        { name: :hv, peak: Peak::Gross } ]
    end

    # Internal: Takes a graph and returns a hash describing the producers and
    # consumers in each layer.
    #
    # For example:
    #
    #   partition_participants(graph)
    #   # => {
    #   #      lv: { consumers: [...], producers: [...] },
    #   #      mv: { consumers: [...], producers: [...] },
    #   #      hv: { consumers: [...], producers: [...] }
    #   #    }
    #
    private_class_method def partition_participants(graph)
      participants = graph.plugin(:merit).order.participants
      by_level = Hash.new { |h, k| h[k] = { consumers: [], producers: [] } }

      participants.each do |part|
        converter = graph.converter(part.key)

        if converter
          config = converter.dataset_get(:merit_order)
          level = config.level
          type  = config.type == :consumer ? :consumers : :producers
        else
          level = PARTICIPANT_LEVELS[part.key] || :hv
          type = :consumers
        end

        by_level[level][type].push(part.load_curve)
      end

      by_level
    end
  end
end
