module Gql::Grammar
  module Functions
    module Core

      # Shortcut for the LOOKUP and ATTR function.
      #
      # Examples
      #
      #   V(foo)               => LOOKUP(foo)
      #   V(foo, demand)       => ATTR(LOOKUP(foo), demand)
      #   V(foo, bar)          => LOOKUP(foo, bar) 
      #   V(foo, bar, demand)  => ATTR(LOOKUP(foo, bar), demand)
      #
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

      # Lookup objects by key(s). 
      #
      # keys - One or more keys.
      #
      # Returns an array of objects (or the key if no object found).
      #
      # Examples
      #
      #   LOOKUP(foo)       => [Converter<foo>]
      #   LOOKUP(foo, bar)  => [Converter<foo>, Converter<bar>]
      #   LOOKUP(foo, not_available)  => [Converter<foo>, "not_available"]
      #
      def LOOKUP(*keys)
        keys.flatten!
        keys.map! do |key| 
          if key.respond_to?(:to_sym)
            # prevents lookup for strings from V(.., "demand*2") or Procs V(.., foo(1))
            @scope.converters(key)
          else
            key
          end
        end
        keys.compact!
        keys
      end

      # Access attributes of one or more objects.
      # 
      # objects   - an object or an array of objects. 
      # attr_name - The String to lookup. 
      #
      # Examples
      #
      # With a single attribute:
      #
      #   ATTR(LOOKUP(foo), demand)      # => 3
      #   ATTR(LOOKUP(foo, bar), demand) # => [3, 5]
      #
      # Composed attributes add "" or ''
      #
      #   ATTR(LOOKUP(foo), 'demand * (3.0 + co2_free)')
      #   ATTR(LOOKUP(foo), "demand * (3.0 + co2_free)")
      #
      # Attributes derived from GQL functions:
      #
      #   ATTR(LOOKUP(foo), primary_demand_of(CARRIER(electricity)))
      #
      # Attributes dervied from GQL functions cannot be inside "" or ''.
      # 
      def ATTR(objects, attr_name)
        objects = [objects] unless objects.is_a?(::Array) 
        
        objects.tap(&:flatten!).map! do |a| 
          a = a.respond_to?(:query) ? a.query : a

          if attr_name.respond_to?(:call)
             a.instance_exec(&attr_name)
          else
            # to_s imported, for when ATTR(..., demand) demand comes through method_missing (as a symbol)
            a.instance_eval(attr_name.to_s)
          end
        end
        objects.length <= 1 ? (objects.first || 0.0) : objects
      end

    end
  end
end