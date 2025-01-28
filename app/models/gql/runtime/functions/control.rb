module Gql::Runtime
  module Functions
    module Control

      def IF(condition, true_stmt, false_stmt)
        if condition
          true_stmt.respond_to?(:call) ? true_stmt.call : true_stmt
        else
          false_stmt.respond_to?(:call) ? false_stmt.call : false_stmt
        end
      end

      def EQUALS(*values)
        a,b = values
        if b.respond_to?(:to_sym)
          # Figure out whether we compare strings or not
          # EQUALS(AREA(code),nl) would compare 'nl' == :nl, so lets convert to_s.
          a.to_s == b.to_s
        else
          a == b
        end
      end

    end
  end
end
