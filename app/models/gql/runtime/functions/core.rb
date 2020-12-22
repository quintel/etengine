module Gql::Runtime
  module Functions
    module Core

      # Shortcut for the LOOKUP and MAP function. Also see {#LOOKUP} and {#MAP}.
      #
      #
      # Instead of node keys you can pass anything inside V(). This
      # works because if LOOKUP does not find a node for an argument
      # it returns that argument itself.
      #
      # @example Lookup a node by key
      #   V(foo)               # = LOOKUP(foo)
      #   # => [<foo>]
      #
      # @example Lookup multiple nodes by their keys
      #   V(foo, bar)          # = LOOKUP(foo, bar)
      #   # => [<foo>, <bar>]
      #
      # @example Lookup a node attribute
      #   V(foo, demand)       # = MAP(LOOKUP(foo), demand)
      #   # => 100
      #
      # @example Lookup multiple node attributes
      #   V(foo, bar, demand)  # = MAP(LOOKUP(foo, bar), demand)
      #   # => [100, 200]
      #
      # @example Nesting of LOOKUPs
      #   V(V(foo), V(bar), demand)  # = MAP(LOOKUP(foo, LOOKUP(bar)), demand)
      #   # => [100, 200]
      #
      # @example Pass arbitrary objects to V()
      #   V(CARRIER(electricity), cost_per_mj) # = MAP( LOOKUP(CARRIER(electricity)), cost_per_mj )
      #   # => 23.3
      #
      # @see #LOOKUP
      # @see #MAP
      # @return [Array] the result of {LOOKUP} if the last argument is a node key.
      # @return [Numeric,Array] the result of {MAP}(LOOKUP(first_key, second_key),last_key) if the last argument is *not* a node key.
      #
      def V(*args)
        value_generic(@scope.energy_graph_helper, args)
      end
      alias VALUE V

      def MV(*args)
        value_generic(@scope.molecule_graph_helper, args)
      end

      # QUERY() or Q() returns the result of another gquery with given key.
      #
      # @example
      #    Q(total_costs)
      #
      # @param [Symbol] key The gquery key
      #
      # @return [Numeric,Array] The result of that gquery. Can be a number, list of nodes, etc.
      #
      def Q(key)
        scope.subquery(key.to_s)
      end
      alias QUERY Q

      # Public: Lookup energy graph objects by their corresponding key(s).
      #
      # For example, one or multiple nodes:
      #   LOOKUP(foo)               # => [Node(foo)]
      #   LOOKUP(foo, bar)          # => [Node(foo), Node(bar)]
      #
      # Elements that are not node keys are simply returned:
      #   LOOKUP(foo, 3.0)          # => [Node(foo), 3.0]
      #   LOOKUP(foo, CARRIER(gas)) # => [Node(foo), Carrier(gas)]
      #
      # `nil` and duplicate elements are removed:
      #   LOOKUP(foo, nil)          # => [Node(foo)]
      #   LOOKUP(foo, LOOKUP(foo))  # => [Node(foo)]
      #
      # Nested arrays are flattened
      #   LOOKUP(foo, LOOKUP(bar, SECTOR(households)))
      #   # => [Node(foo), Node(bar), ...]
      #
      # keys - Provided keys should be energy graph node keys or Qernel objects (for example,
      #        `L(CARRIER(foo))`).
      #
      # Returns an array of the elements of the query: matching nodes or objects. Duplicates and nil
      # values are removed.
      def L(*keys)
        lookup_generic(@scope.energy_graph_helper, keys)
      end
      alias LOOKUP L

      # Public: Lookup energy graph objects by their corresponding key(s).
      #
      # See Functions::Core#V.
      #
      # keys - Provided keys should be energy graph node keys or Qernel objects (for example,
      #        `L(CARRIER(foo))`).
      #
      # Returns an array of the elements of the query: matching nodes or objects. Duplicates and nil
      # values are removed.
      def ML(*keys)
        lookup_generic(@scope.molecule_graph_helper, keys)
      end
      alias MLOOKUP ML

      # Access attributes of one or more objects.
      #
      # === Single and composed attributes
      #
      # To query a single attribute simply pass it. You can
      # put it inside '', "" or not.
      #
      # To join multiple attributes and numbers surround it
      # with "" or ''.
      #
      # === GQL functions as arguments
      #
      # You can pass a GQL function as an argument to a *single*
      # method. This only works if you for a single method.
      # Attributes dervied from GQL functions cannot be inside "" or ''.
      #
      # @example With a single attribute:
      #   MAP(L(foo), demand)      # => 100
      #   MAP(L(foo), "demand")    # => 100
      #   MAP(L(foo, bar), demand) # => [100, 200]
      #
      # @example Composed attributes add "" or ''
      #   MAP(L(foo), 'demand * (3.0 + free_co2_factor)')
      #   MAP(L(foo), "demand * (3.0 + free_co2_factor)")
      #
      # @example GQL functions as arguments
      #   MAP(L(foo), primary_demand_of(CARRIER(electricity)))
      #   MAP(L(foo), "primary_demand_of(CARRIER(electricity))")
      #   MAP(L(foo), demand * AREA(number_of_households))
      #   MAP(L(foo), "demand * AREA(number_of_households)"))))
      #
      # @example Access other Qernel objects
      #   MAP(L(foo), 'demand * area.number_of_households')
      #
      # @param [Array] elements The elements to query the attributes.
      #                E.g. LOOKUP(...), SECTOR(...)
      # @param [Symbol,String] attr_name Single or combined attribute
      # @return [Array] An array of the results if multiple elements given
      # @return [Numeric] The resulting number if only one element is given
      #
      def M(elements, attr_name)
        elements = [elements] unless elements.is_a?(::Array)
        elements.tap(&:flatten!).map! do |element|
          GET(element, attr_name)
        end
        elements.length <= 1 ? (elements.first || 0.0) : elements
      end
      alias MAP M
      # @deprecated
      alias ATTR M
      # @deprecated
      alias A M

      # Retrieves the attribute from one *single* object.
      # The main reason for this function is that we can have better
      # support for the debugger.
      #
      # This is used internally by MAP/M function and does not work
      # in conjunction with L() as this returns an array.
      #
      def GET(object, attr_name)
        object = object.respond_to?(:query) ? object.query : object

        if attr_name.respond_to?(:call)
          if !attr_name.respond_to?(:arity) || attr_name.arity.zero?
            # Backwards compatibility; rather than yielding each element in
            # the array, sets "self" to each object.
            object.instance_exec(&attr_name)
          else
            attr_name.call(object)
          end
        else
          # to_s imported, for when MAP(..., demand) demand comes through method_missing (as a symbol)
          object.instance_eval(attr_name.to_s)
        end
      end

      private

      # Internal: Looks up objects in a graph and extracts values. See Functions::Core#V.
      def value_generic(graph_helper, args)
        # Given: V(..., primary_demand_of( CARRIER(...) ))
        # args.last would be a Rubel message. Do not call LOOKUP for these.
        last_key = args.last.respond_to?(:call) ? [] : try_lookup(graph_helper, args.last)

        if args.length == 1
          last_key
        elsif last_key.length.positive?
          lookup_generic(graph_helper, args)
        else
          attr_name = args.pop
          M(lookup_generic(graph_helper, args), attr_name)
        end
      end

      # Internal: Looks up objects in a graph. See Functions::Core#L.
      def lookup_generic(graph_helper, keys)
        keys.flatten!
        keys.map! do |key|
          # Given LOOKUP( key_1 ) key_1 will respond_to to_sym because
          # it comes from Rubel::Base#method_missing, which returns Symbols.
          if key.respond_to?(:to_sym)
            # prevents lookup for strings from V(.., "demand*2") or Rubel
            # messages V(.., foo(1))
            graph_helper.nodes(keys).tap do |arr|
              if arr.empty?
                ActiveSupport::Notifications.instrument(
                  "warn: No #{graph_helper.graph.name} node found with key: #{key}"
                )
              end
            end
          else
            key
          end
        end
        keys.flatten!
        keys.compact!
        keys.uniq!
        keys
      end

      # Internal: Similar to LOOKUP, checks if a node with the key exists. Does not emit a warning
      # if none is found. Used within Functions::Core#V.
      def try_lookup(graph_helper, key)
        if key.respond_to?(:to_sym)
          # Prevents lookup for strings from V(.., "demand*2") or Rubel messages V(.., foo(1)).
          graph_helper.nodes(key)
        else
          [key]
        end
      end
    end
  end
end
