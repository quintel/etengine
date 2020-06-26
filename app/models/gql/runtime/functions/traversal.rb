module Gql::Runtime
  module Functions
    # @example Example used in description
    #
    #   Example Graph
    #                   +---------------+        +--> gas_1
    #                   |               |        |
    #   loss1 <- (loss)-|   foo         |- (gas)-+--> gas_2
    #                   |               |
    #   heat1 <- (heat)-|  <Node>  |- (oil)-+
    #                   |               |        +--> oil_1
    #                   +---------------+
    #
    module Traversal

      # ELEMENT_AT( SORT_BY(GROUP(electricity); demand), 0) => node with smallest demand
      def ELEMENT_AT(*nodes)
        index = nodes.last.to_i
        nodes.flatten[index]
      end

      # Returns the first element of the array.
      #
      # Examples
      #
      #   LAST(V(1,2,3)) # => 3
      #   LAST(LOOKUP(foo, bar)) # => :bar
      #
      def LAST(*value_terms)
        value_terms.flatten.last
      end

      # Returns the last element of the array.
      #
      # Examples
      #
      #   LAST(V(1,2,3)) # => 1
      #   LAST(LOOKUP(foo, bar)) # => :foo
      #
      def FIRST(*value_terms)
        value_terms.flatten.first
      end

      # Returns the {Qernel::Edge} that goes from the first to the second node.
      #
      # EDGE() performs a LOOKUP on the two keys.
      #
      # Examples
      #
      #   EDGE( foo, bar ) => Qernel::Edge
      #   # works in the other direction too
      #   EDGE( bar, foo ) => Qernel::Edge
      #
      def EDGE(lft, rgt)
        lft,rgt = LOOKUP(lft, rgt).flatten
        if lft.nil? || rgt.nil?
          nil
        else
          edge = lft.input_edges.detect{|l| l.rgt_node == rgt.node}
          edge ||= lft.output_edges.detect{|l| l.lft_node == rgt.node}
          edge
        end
      end

      # @example All edges on a node
      #   EDGES(L(foo))
      #   # => [foo->gas_1, foo->gas_2, loss1->foo, heat1->foo]
      #
      # @example All output edges with a constraint
      #   EDGES(L(foo), "share?")
      #   EDGES(L(foo), "flexible?")
      #   EDGES(L(foo), "flexible? && share >= 1.0")
      #
      # @example All edges of a given carrier/slot
      #    EDGES(OUTPUT_SLOTS(foo, heat)) # => [heat->foo]
      #
      # @example Edges of multiple nodes
      #   EDGES(L(foo, bar))
      #
      def EDGES(value_terms, arguments = nil)
        edges_for(value_terms, arguments)
      end

      # Get the output (to the left) slots of node(s).
      #
      # @example All input slots
      #   OUTPUT_SLOTS(foo)           #=> [(loss)-foo, (heat)-foo]
      #   OUTPUT_SLOTS(L(foo))        #=> [(loss)-foo, (heat)-foo]
      #   OUTPUT_SLOTS(L(foo,bar))    #=> [(loss)-foo, (heat)-foo, ...]
      #
      # @example All input slots
      #   OUTPUT_SLOTS(foo, loss) #=> [(loss)-foo]
      #
      def OUTPUT_SLOTS(*args)
        carrier = args.pop if args.length > 1
        nodes = LOOKUP(args).flatten
        flatten_uniq nodes.compact.map{|c| carrier ? c.output(carrier.to_sym) : c.outputs}
      end

      # Get the input (to the right) slots of node(s).
      #
      # @example All input slots
      #   INPUT_SLOTS(foo) #=> [foo-(gas), foo-(oil)]
      #
      # @example All input slots
      #   INPUT_SLOTS(foo, gas) #=> [foo-(gas)]
      #
      def INPUT_SLOTS(*args)
        carrier = args.pop if args.length > 1
        nodes = LOOKUP(args).flatten
        flatten_uniq nodes.compact.map{|c| carrier ? c.input(carrier.to_sym) : c.inputs}
      end

      # @example All input edges
      #   INPUT_EDGES(L(foo))
      #
      # @example All input edges with a constraint
      #   INPUT_EDGES(L(foo), "share?")
      #   INPUT_EDGES(L(foo), "flexible?")
      #   INPUT_EDGES(L(foo), "flexible? && share >= 1.0")
      #
      # @example All input edges of a given carrier/slot
      #    INPUT_EDGES(INPUT_SLOTS(foo, oil)) # => [foo->oil_1]
      #
      # @example Input edges of multiple nodes
      #   INPUT_EDGES(L(foo, bar))
      #
      def INPUT_EDGES(value_terms, arguments = nil)
        edges_for(value_terms, arguments, [:input_edges, :edges])
      end

      # @example All output edges
      #   OUTPUT_EDGES(L(foo))
      #
      # @example All output edges with a constraint
      #   OUTPUT_EDGES(L(foo), "share?")
      #   OUTPUT_EDGES(L(foo), "flexible?")
      #   OUTPUT_EDGES(L(foo), "flexible? && share >= 1.0")
      #
      # @example All output edges of a given carrier/slot
      #    OUTPUT_EDGES(OUTPUT_SLOTS(foo, heat)) # => [heat->foo]
      #
      # @example Output edges of multiple nodes
      #   OUTPUT_EDGES(L(foo, bar))
      #
      def OUTPUT_EDGES(value_terms, arguments = nil)
        edges_for(value_terms, arguments, [:output_edges, :edges])
      end

      #######
      private
      #######

      # Internal: Returns edges from one or more Qernel objects.
      #
      # The `using` parameter allows you to provide an array of methods to try
      # in order to retrieve the edges for each object. For example, when
      # looking for output edges, you might use `[:output_edges, :edges]`.
      # Objects with an `output_edges` method (Node) would use that,
      # otherwise `edges` will be used (Slot).
      #
      # `arguments` may contain a single string used to filter out
      # non-matching edges.
      #
      # @example All edges from two objects.
      #   edges_for(L(node_one, node_two))
      #
      # @example Filtering
      #   edges_for(L(node_one), '! flexible?')
      #
      # @example Selecting only output edges.
      #   edges_for(L(node_one), nil, [:output_edges])
      #
      # @example Selecting output edges, falling back to all edges.
      #   edges_for(L(node_one, slot_one), nil, [:output_edges, :edges])
      #
      def edges_for(value_terms, arguments = nil, using = [:edges])
        value_terms.flatten

        edges = flatten_uniq(value_terms).map! do |obj|
          if method = using.detect { |method| obj.respond_to?(method) }
            obj.public_send(method)
          end
        end

        edges.compact!
        edges.flatten!

        if arguments.present?
          filter = arguments.is_a?(Array) ? arguments.first : arguments

          # If the filter is a symbol, it is probably selcting for edge type,
          # e.g. OUTPUT_EDGES(..., constant). Make sure it runs the correct
          # predicate method:
          filter = "#{ filter }?" if filter.is_a?(Symbol)

          edges.select! { |edge| edge.instance_eval(filter.to_s) }
        end

        edges
      end

    end # Traversal
  end # Functions
end # Gql::Runtime
