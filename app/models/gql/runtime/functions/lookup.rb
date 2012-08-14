module Gql::Runtime
  module Functions
    module Lookup

      # Returns the present value of the the gquery, when given a key.
      # If the argument is a lambda ( -> { ... }), runs it for the present.
      #
      # @param queryThe gquery lookup key or a lambda with GQL statement
      #
      # @example
      #
      #   QUERY_PRESENT(graph_year)              # => 2010
      #   QUERY_PRESENT( -> { GRAPH(year) } )    # => 2010
      #
      def QUERY_PRESENT(query)
        scope.gql.present.query(query)
      end

      # Returns the future value of the the gquery, when given a key.
      # If the argument is a lambda ( -> { ... }), runs it for the future.
      #
      # @param query The gquery lookup key or a lambda with GQL statement
      # @example
      #
      #   QUERY_FUTURE(graph_year)              # => 2050
      #   QUERY_FUTURE( -> { GRAPH(year) } )    # => 2050
      #
      def QUERY_FUTURE(query)
        scope.gql.future.query(query)
      end

      # Returns the first term for the present graph and the second for
      # the future graph.
      #
      # DEPRECATED: this might not work right now
      #
      def MIXED(present_term, future_term)
        scope.graph.present? ? present_term : future_term
      end

      # Returns an attribute {Qernel::Graph}.
      #
      # keys - The name of the attribute.
      #
      # Advanced
      #
      # GRAPH() without a key returns {Qernel::Graph}
      #
      #   GRAPH() # => <Qernel::Graph>
      #
      # Examples
      #
      #   GRAPH(...) => ...
      #   GRAPH() => <Qernel::Graph>
      #
      def GRAPH(*keys)
        keys.empty? ? scope.graph : scope.graph_query(keys.first)
      end


      # Returns an Array of all {Qernel::Converter}. Use wisely, as this
      # could become a performance killer.
      #
      # Examples
      #
      #   ALL()
      #
      def ALL(*keys)
        scope.all_converters
      end

      # Returns an Array of {Qernel::Converter} for given group.
      #
      # Examples
      #
      #   GROUP(households)
      #
      def GROUP(*keys)
        scope.group_converters(keys)
      end
      alias G GROUP

      # Returns an Array of {Qernel::Converter} for given sector.
      #
      # Examples
      #
      #   SECTORS(households)
      #
      def SECTOR(*keys)
        scope.sector_converters(keys)
      end

      # Returns an Array with {Qernel::Converter} for given energy use.
      #
      # See Qernel::Converter::USES
      #
      # Examples
      #
      #   USE(energetic)
      #   USE(non_energetic)
      #   USE(undefined)
      #
      def USE(*keys)
        scope.use_converters(keys)
      end

      # Returns an Array of {Qernel::Carrier} for given key(s)
      #
      # Examples
      #
      #   CARRIER(electricity) # => [ <Qernel::Carrier electricity> ]
      #   CARRIER(electricity, network_gas) # => [<Qernel::Carrier electricity>, <Qernel::Carrier network_gas>]
      #
      def CARRIER(*keys)
        scope.carriers(keys)
      end

      # Returns an attribute {Qernel::Area}
      #
      # keys - The name of the attribute
      #
      # AREA() without a key returns {Qernel::Area}
      #
      #   AREA() # => <Qernel::Area>
      #
      # Examples
      #
      #   AREA(number_households) => 7349500.0
      #
      def AREA(*keys)
        keys.empty? ? scope.graph.area : scope.area(keys.first)
      end

      # Returns the start_value defined in fce_values.yml
      #
      # @example
      #      FCE_START_VALUE(CARRIER(coal), australia)
      #      FCE_START_VALUE(CARRIER(coal), "australia")
      #
      def FCE_START_VALUE(carrier, country)
        scope.graph.fce_start_value(carrier, country)
      end
    end
  end
end
