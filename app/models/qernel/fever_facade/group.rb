# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Defines a set of consumers and producers which will be computed in Fever.
    # For example, :space_heating or :hot_water. Each group is run in a separate
    # Fever instance.
    class Group
      attr_reader :name

      # Public: Creates a new Group.
      #
      # name   - The name of the group as a Symbol.
      # plugin - The FeverFacade::Manager to which the group belongs.
      #
      # Returns a Group.
      def initialize(name, plugin)
        @name    = name
        @context = Context.new(plugin, plugin.graph)
      end

      # Public: Sets up calculator where consumers and producers are matched
      def calculators
        @calculators ||= Qernel::FeverFacade::Calculators.new(
          ordered_producers, ordered_consumers, context
        )
      end

      # Public: Instructs the calculator to compute a single frame.
      #
      # frame - The frame number to be calculated.
      #
      # Returns nothing.
      delegate :calculate_frame, to: :calculators

      # Internal: The adapters which map nodes from the graph to activities
      # within Fever.
      delegate :adapters, to: :calculators

      # Public: Returns a curve which describes the demand for electricity
      # caused by the activities within the calculator.
      def elec_demand_curve
        @elec_demand_curve ||= ElectricityDemandCurve.from_adapters(adapters)
      end

      # Public: Returns the adapter for the node matching `key` or nil if
      # the node is not a participant in the group.
      def adapter(key)
        adapters.find { |a| a.node.key == key } if @context.graph.node(key).fever
      end

      # We need: priority of producrers (etsource config)
      # priority of consumers (etsource config)
      def ordered_producers
        # Etsource::Fever.group(@name).keys(:producers) <- and then have them ordered from the config
        # TODO: INCLUDING VALIDATION!! THAT THEY ARE NODES IN THE GROUP -> or already in Atlas?
      end

      def ordered_consumers
        # TODO: INCLUDING VALIDATION!! THAT THEY ARE NODES IN THE GROUP -> or already in Atlas?
      end

      def producer_adapters
        adapters.select { |adapter| adapter.config.type == :producer }
      end
    end
  end
end
