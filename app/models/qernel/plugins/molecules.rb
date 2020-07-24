# frozen_string_literal: true

module Qernel
  module Plugins
    # Simple implementation of a molecules graph. Each energy graph has a Molecules plugin which
    # holds the molecules graph, calculation of which is triggered after the first calculation of
    # the energy graph.
    class Molecules
      include Plugin

      after :finish, :calculate

      # The molecule graph. If this is called after the energy graph calculation, the molecule graph
      # demands will also have been calculated.
      #
      # Returns a Qernel::Graph.
      attr_reader :molecule_graph

      def self.enabled?(graph)
        graph.energy?
      end

      # Public: A unique name to represent the plugin.
      #
      # Returns a symbol.
      def self.plugin_name
        :molecules
      end

      def initialize(graph)
        super

        @molecule_graph = Etsource::Loader.instance.molecule_graph
        @molecule_graph.dataset = @graph.dataset
      end

      private

      # Internal: For each molecule node with a conversion, determines its demand from the
      # appropriate energy source node.
      def calculate
        # Dataset is nil in some tests. Skip the molecule graph calculation.
        return nil if Rails.env.test? && @graph.dataset.nil?

        @molecule_graph.dataset = @graph.dataset

        Etsource::Molecules.import.each do |node_key|
          molecule_node = @molecule_graph.node(node_key)
          conversion    = molecule_node.from_energy
          energy_node   = @graph.node(conversion.source)

          molecule_node.demand = demand_from_source(energy_node, conversion)
        end

        @molecule_graph.calculate
      end

      # Internal: Reads the appropriate value from the source node and calculates what should be
      # set on the molecule node.
      #
      # Conversions without a "direction" are assumed to take the demand of the source node and
      # optionally multiply it by the "conversion" attribute. Those whose direction is :input or
      # :output will specify each carrier and conversion separately.
      #
      # Returns a Numeric.
      def demand_from_source(source, conversion)
        direction = conversion.direction

        if direction.nil?
          source.demand * conversion.conversion_of(nil)
        else
          conversion.conversion.sum do |carrier, _|
            slot = conversion_slot(source, direction, carrier)
            factor = conversion_factor(slot, conversion)

            slot.external_value * factor
          end
        end
      end

      def conversion_factor(slot, conversion)
        factor = conversion.conversion_of(slot.carrier.key)

        return factor if factor.is_a?(Numeric)

        if factor.to_s.start_with?('carrier:')
          attribute = factor[8..].strip
          begin
            factor = slot.carrier.public_send(attribute)
          rescue NoMethodError
            raise "Invalid attribute for #{slot.carrier.key} carrier in `from_energy` " \
                  "on #{slot.node.key} node"
          end
        end

        factor
      end

      def conversion_slot(source, direction, carrier)
        case direction
        when :input  then source.input(carrier)
        when :output then source.output(carrier)
        end
      end
    end
  end
end
