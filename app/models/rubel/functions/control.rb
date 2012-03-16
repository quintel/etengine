module Rubel
  module Functions
    module Control

      def IF(condition, true_stmt, false_stmt)
        if condition
          true_stmt.respond_to?(:call) ? true_stmt.call : true_stmt
        else
          false_stmt.respond_to?(:call) ? false_stmt.call : false_stmt
        end
      end

    end
  end
end
