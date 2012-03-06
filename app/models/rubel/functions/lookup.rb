module Rubel
  module Functions
    module Lookup

      def GRAPH(*keys)
        scope.graph_query(keys.first)
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
        scope.area(keys.first)
      end
    end
  end
end
