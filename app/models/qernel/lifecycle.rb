module Qernel
  # Manages setup and calculation of a Graph, and running callbacks from plugins
  # as required by the scenario.
  class Lifecycle
    # Public: A hash containing the plugins which were used as part of the
    # calculation. Each key is the name of the plugin, and each value is the
    # plugin itself.
    #
    # Returns a hash.
    attr_reader :plugins

    # Public: Creates a new Lifecycle for calculating the given +graph+.
    def initialize(graph)
      @graph            = graph
      @must_recalculate = false

      @plugins = Hash[Qernel::Graph::PLUGINS
        .select { |plugin| plugin.enabled?(@graph) }
        .map    { |plugin| [plugin.plugin_name, plugin.new(graph)] }]
    end

    # Public: Calculates the graph, handling plugins and callbacks as needed.
    #
    # Returns nothing.
    def calculate
      with_callback(:first_calculation) { do_calculation }

      while @must_recalculate
        @graph.retaining_lifecycle do
          with_callback(:recalculation) { do_calculation }
        end
      end

      with_callback(:finish) {}
    end

    # Public: A helper function which can be triggered by a plugin callback,
    # which tells the Lifecycle that the graph needs to be recalculated. Likely
    # the plugin added some extra data which will affect the outcome of the
    # calculation.
    #
    # Returns nothing.
    def must_recalculate!
      @must_recalculate = true
    end

    # Public: Helper method which sends callbacks when a plugin changes the dataset attached to the
    # graph.
    #
    # Prefer this over Graph#dataset= directly to ensure that other plugins are informed of the
    # change of dataset.
    def attach_dataset(dataset)
      with_callback(:change_dataset) do
        # Detaching the dataset clears the goals. This would ordinarily be correct behaviour, but we
        # need to preserve them for the second calculation.
        @graph.retaining_lifecycle do
          @graph.detach_dataset!
          @graph.dataset = dataset
        end
      end
    end

    #######
    private
    #######

    # Internal: Triggers the "before" callback for the named +event+, yields to
    # a block for execution, then runs the "after" callbacks.
    #
    # Returns true.
    def with_callback(event)
      @plugins.each_value do |plugin|
        plugin.trigger(:before, event, self)
      end

      yield

      @plugins.each_value do |plugin|
        plugin.trigger(:after, event, self)
      end

      true
    end

    # Internal: Calculates the graph, taking care of internal book-keeping and
    # recalculation as needed.
    #
    # Returns nothing.
    def do_calculation
      @must_recalculate = false

      with_callback(:calculation) do
        @graph.calculation_loop
      end
    end
  end # Lifecycle
end # Qernel
