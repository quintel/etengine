module Etsource
  # Contains helpers used to build the structure of the graph in ETEngine
  # using the ETSource documents.
  module FromAtlas
    class << self
      # Public: Given an Atlas +node+, creates the corresponding Converter for
      # use in the graph.
      #
      # node - An Atlas::Node.
      #
      # Returns a Qernel::Converter.
      def converter(node)
        Qernel::Converter.new(
          key:                  node.key.to_sym,
          sector_id:            node.sector.to_sym,
          use_id:               node.use.try(:to_sym),
          energy_balance_group: node.energy_balance_group.try(:to_sym),
          groups:               node.groups
        )
      end

      # Public: Given an Atlas +slot+, creates the corresponding Slot for use
      # in the graph.
      #
      # slot - An Atlas::Slot.
      #
      # Returns a Qernel::Slot.
      def slot(slot, converter, carrier)
        type = if slot.carrier == :loss
          :loss
        elsif slot.is_a?(Atlas::Slot::Elastic)
          :elastic
        end

        slot_from_data(converter, carrier, slot.direction, type)
      end

      # Public: Given data about a +slot+, creates the corresponding Slot.
      #
      # converter   - The Qernel::Converter to which the slot belongs.
      # carrier     - The Qernel::Carrier.
      # direction   - Input or output slot? :in or :out.
      # type        - What type of slotto create. nil, :elastic, or :loss.
      #
      # Returns a Qernel::Slot
      def slot_from_data(converter, carrier, direction, type = nil)
        Qernel::Slot.factory(
          type,
          slot_key(converter.key, carrier.key, direction),
          converter,
          carrier,
          direction == :in ? :input : :output
        )
      end

      # Public: Given an Atlas +edge+, creates the corresponding Link for use
      # in the graph.
      #
      # Link#initialize automatically establishes the connection between the
      # supplier and consumer, hence the bang!
      #
      # edge     - The Atlas::Edge.
      # consumer - The consumer (input) converter.
      # supplier - The supplier (output) converter.
      # carrier  - The Qernel::Carrier.
      #
      # Returns a Qernel::Link.
      def link!(edge, consumer, supplier, carrier)
        Qernel::Link.new(
          link_key(edge),
          consumer,
          supplier,
          carrier,
          edge.type,
          edge.reversed?
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
      def link_key(edge)
        type_key =
          case edge.type
            when :share             then :s
            when :flexible          then :f
            when :inversed_flexible then :i
            when :dependent         then :d
            when :constant          then :c
          end

        arrow =
          if edge.reversed?
            "<-- #{ type_key } --"
          else
            "-- #{ type_key } -->"
          end

        "#{ slot_key(edge.consumer, edge.carrier, :in) } " \
        "#{ arrow } " \
        "#{ slot_key(edge.supplier, edge.carrier, :out) }"
      end

    end # class << self
  end # FromAtlas
end # Etsource
