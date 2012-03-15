module Rubel
  module Functions
    module Core

      # V(foo) => LOOKUP(foo)
      # V(foo, bar) => if bar is converter: LOOKUP(foo, bar) 
      # V(foo, bar) => if bar is not converter: ATTR(LOOKUP(foo), bar) 
      # V(foo, bar, baz) => if baz is not converter: ATTR(LOOKUP(foo, bar), baz)
      def V(*args)
        last_key = LOOKUP(args.last)
        last_key.flatten!
        
        if args.length == 1
          last_key
        elsif last_key.length > 0
          LOOKUP(*args)
        else
          attr_name = args.pop
          ATTR(LOOKUP(*args), attr_name)
        end
      end
      alias VALUE V

      def QUERY(key)
        scope.subquery(key.to_s)
      end
      alias Q QUERY

      # returns empty array instead of nil when nothing found  
      def LOOKUP(*keys)
        keys.flatten!
        keys.map! do |key| 
          if key.respond_to?(:to_sym)
            # prevents lookup for strings or procs, like when doing V(.., "demand*2"), V(.., foo(1))
            @scope.lookup(key)
          else
            key
          end
        end
        keys.compact!
        keys
      end

      def IF(condition, true_stmt, false_stmt)
        if condition
          true_stmt.respond_to?(:call) ? true_stmt.call : true_stmt
        else
          false_stmt.respond_to?(:call) ? false_stmt.call : false_stmt
        end
      end

      def ATTR(args, attr_name)
        args = [args] unless args.is_a?(::Array) 
        args.flatten!
        args.map! do |a| 
          a = a.respond_to?(:query) ? a.query : a
          if attr_name.respond_to?(:call)
             a.instance_exec(&attr_name)
          else
            # to_s imported, for when ATTR(..., demand) demand comes through method_missing (as a symbol)
            a.instance_eval(attr_name.to_s)
          end
        end
        args.length <= 1 ? (args.first || 0.0) : args
      end

    end
  end
end