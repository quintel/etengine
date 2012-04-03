module Gql::Grammar
  module Functions
    module Lookup

      def ALL(*keys)
        scope.all_converters
      end

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

      # With this function you can run two different statements for present and future.
      # 
      def MIXED(present_term, future_term)
        scope.graph.present? ? present_term : future_term
      end

      def GRAPH(*keys)
        keys.empty? ? scope.graph : scope.graph_query(keys.first)
      end
  
      def GROUP(*keys)
        scope.group_converters(keys)
      end
      alias G GROUP

      def SECTOR(*keys)
        scope.sector_converters(keys)
      end

      def USE(*keys)
        scope.use_converters(keys)
      end

      def CARRIER(*keys)
        scope.carriers(keys)
      end

      def AREA(*keys)
        keys.empty? ? scope.area : scope.area(keys.first)
      end
    end
  end
end
