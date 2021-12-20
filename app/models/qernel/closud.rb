# frozen_string_literal: true

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
    }.freeze

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
      adapters = graph.plugin(:merit).adapters.values.select(&:installed?)

      participants = adapters.map do |adapter|
        Array(adapter.participant).map { |v| { participant: v, node: adapter.node } }
      end.flatten

      by_level = Hash.new do |h, k|
        h[k] = { consumers: [], producers: [], flexibles: [] }
      end

      participants.each do |pair|
        node = pair[:node]
        part = pair[:participant]

        if node
          config = node.merit_order
          level = config.level
          type = closud_type(part)

          next if level == :omit
        else
          level = PARTICIPANT_LEVELS[part.key] || :hv
          type = :consumers
        end

        by_level[level][type].push(part.load_curve)
      end

      by_level
    end

    private_class_method :partition_participants

    # Internal: Converts the merit config type to the appropriate Closud type.
    def closud_type(part)
      if part.flex?
        :flexibles
      elsif part.user?
        :consumers
      else
        :producers
      end
    end

    private_class_method :closud_type
  end
end
