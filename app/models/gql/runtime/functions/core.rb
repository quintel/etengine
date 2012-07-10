module Gql::Runtime
  module Functions
    module Core

      # Shortcut for the LOOKUP and MAP function. Also see {#LOOKUP} and {#MAP}. 
      #
      #
      # Instead of converter keys you can pass anything inside V(). This 
      # works because if LOOKUP does not find a converter for an argument
      # it returns that argument itself.
      #
      # @example Lookup a converter by key
      #   V(foo)               # = LOOKUP(foo)
      #   # => [<foo>]
      #
      # @example Lookup multiple converters by their keys
      #   V(foo, bar)          # = LOOKUP(foo, bar)
      #   # => [<foo>, <bar>]
      #
      # @example Lookup a converter attribute
      #   V(foo, demand)       # = MAP(LOOKUP(foo), demand)
      #   # => 100
      #
      # @example Lookup multiple converter attributes
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
      # @return [Array] the result of {LOOKUP} if the last argument is a converter key.
      # @return [Numeric,Array] the result of {MAP}(LOOKUP(first_key, second_key),last_key) if the last argument is *not* a converter key.
      #
      def V(*args)
        # Given: V(..., primary_demand_of( CARRIER(...) )) 
        # args.last would be a Proc. Do not call a LOOKUP for Procs.
        last_key = args.last.is_a?(Proc) ? [] : LOOKUP(args.last)
        last_key.flatten!
        
        if args.length == 1
          last_key
        elsif last_key.length > 0
          LOOKUP(*args)
        else
          attr_name = args.pop
          MAP(LOOKUP(*args), attr_name)
        end
      end
      alias VALUE V


      # QUERY() or Q() returns the result of another gquery with given key.
      #
      # @example 
      #    Q(total_costs)
      #
      # @param [Symbol] key The gquery key
      #
      # @return [Numeric,Array] The result of that gquery. Can be a number, list of converters, etc.
      # 
      def Q(key)
        scope.subquery(key.to_s)
      end
      alias QUERY Q

      # Lookup objects by their corresponding key(s). 
      #
      #
      # @example One or multiple converters
      #   LOOKUP(foo)               # => [<Converter foo>]
      #   LOOKUP(foo, bar)          # => [<Converter foo>, <Converter bar>]
      #
      # @example Elements that are not converter keys are simply returned
      #   LOOKUP(foo, 3.0)          # => [<Converter foo>, 3.0]
      #   LOOKUP(foo, CARRIER(gas)) # => [<Converter foo>,<Carrier Gas>]
      #
      # @example nil and duplicate elements are removed
      #   LOOKUP(foo, nil)          # => [<Converter foo>]
      #   LOOKUP(foo, LOOKUP(foo))  # => [<Converter foo>]
      #
      # @example Nested arrays are flattened
      #   LOOKUP(foo, LOOKUP(bar, SECTOR(households)))  
      #   # => [<Converter foo>,<Converter bar>,...]
      #
      # @param [Array] keys One or more of:
      #   - Converter key
      #   - {Qernel::Base} objects, e.g. LOOKUP(CARRIER(foo))
      #   - Arrays thereof, e.g. LOOKUP(LOOKUP(),LOOKUP())
      #
      # @return [Array] An array of the elements of the query. 
      #                 Duplicates and nil values are removed.
      #
      def L(*keys)
        keys.flatten!
        keys.map! do |key| 
          # Given LOOKUP( key_1 ) key_1 will respond_to to_sym because
          # it comes from Rubel::Base#method_missing, which returns Symbols.
          if key.respond_to?(:to_sym)
            # prevents lookup for strings from V(.., "demand*2") or Procs V(.., foo(1))
            @scope.converters(key)
          else
            key
          end
        end
        keys.flatten!
        keys.compact!
        keys.uniq!
        keys
      end
      alias LOOKUP L

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
      #   MAP(L(foo), 'demand * (3.0 + co2_free)')
      #   MAP(L(foo), "demand * (3.0 + co2_free)")
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
          object.instance_exec(&attr_name)
        else
          # to_s imported, for when MAP(..., demand) demand comes through method_missing (as a symbol)
          object.instance_eval(attr_name.to_s)
        end
      end
    end
  end
end