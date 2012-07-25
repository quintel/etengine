module Gql::Runtime
  module Functions
    module Lookup

      # Runs the gquery with given key for the present year only.
      #
      # gquery_key - The gquery lookup key. 
      #
      # Returns the result of the gquery for only the present year. 
      #
      # Examples
      #
      #   QUERY_PRESENT(graph_year)   # => 2010
      #
      def QUERY_PRESENT(gquery_key)
        scope.gql.present.subquery(gquery_key.to_s)
      end

      # Runs the gquery with given key for the future year only.
      #
      # gquery_key - The gquery lookup key. 
      #
      # Returns the result of the gquery for only the future year. 
      #
      # Examples
      #
      #   QUERY_FUTURE(graph_year)    # => 2050
      #
      def QUERY_FUTURE(gquery_key)
        scope.gql.future.subquery(gquery_key.to_s)
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
    end
  end
end
