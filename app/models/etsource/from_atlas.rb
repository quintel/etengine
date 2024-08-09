module Etsource
  # Contains helpers used to build the structure of the graph in ETEngine
  # using the ETSource documents.
  module FromAtlas
    class << self
      # Public: Given an Atlas +node+, creates the corresponding Node for
      # use in the graph.
      #
      # node - An Atlas::Node.
      #
      # Returns a Qernel::Node.
      def node(node)
        Qernel::Node.new(
          key: node.key.to_sym,
          graph_name: node.graph_config.name,
          groups: node.groups,
          presentation_group: node.presentation_group,
          sector_id: node.sector&.to_sym,
          use_id: node.use&.to_sym
        )
      end

      # Public: Given an Atlas +slot+, creates the corresponding Slot for use
      # in the graph.
      #
      # slot - An Atlas::Slot.
      #
      # Returns a Qernel::Slot.
      def slot(slot, node, carrier)
        type =
          if slot.carrier == :loss
            :loss
          elsif slot.is_a?(Atlas::Slot::Elastic)
            :elastic
          elsif slot.is_a?(Atlas::Slot::Dynamic)
            :edge_based
          end

        slot_from_data(node, carrier, slot.direction, type)
      end

      # Public: Given data about a +slot+, creates the corresponding Slot.
      #
      # node   - The Qernel::Node to which the slot belongs.
      # carrier     - The Qernel::Carrier.
      # direction   - Input or output slot? :in or :out.
      # type        - What type of slotto create. nil, :elastic, or :loss.
      #
      # Returns a Qernel::Slot
      def slot_from_data(node, carrier, direction, type = nil)
        Qernel::Slot.factory(
          type,
          slot_key(node.key, carrier.key, direction),
          node,
          carrier,
          direction == :in ? :input : :output
        )
      end

      # Public: Given an Atlas +edge+, creates the corresponding Edge for use
      # in the graph.
      #
      # Edge#initialize automatically establishes the connection between the
      # supplier and consumer, hence the bang!
      #
      # edge     - The Atlas::Edge.
      # consumer - The consumer (input) node.
      # supplier - The supplier (output) node.
      # carrier  - The Qernel::Carrier.
      #
      # Returns a Qernel::Edge.
      def edge!(edge, consumer, supplier, carrier)
        Qernel::Edge.new(
          edge_key(edge),
          consumer,
          supplier,
          carrier,
          edge.type,
          edge.reversed?,
          edge.groups,
          circular: edge.circular
        )
      end

      # Internal: Given a node key, carrier key, and direction, returns the
      # key to be assigned to a slot with those attributes.
      #
      # Returns a Symbol.
      def slot_key(node_key, carrier_key, direction)
        if direction == :in
          :"#{ node_key }-(#{ carrier_key })"
        else
          :"(#{ carrier_key })-#{ node_key }"
        end
      end

      # Internal: Given a Atlas edge, determines what the key of that edge is
      # when used in ETEngine.
      #
      # Returns a string.
      def edge_key(edge)
        edge.key.to_s
      end
    end # class << self
  end # FromAtlas
end # Etsource
