module Gql::Runtime
  module Functions
    module Update

      # Lookup a named time series value by year.
      #
      # @example
      #     TIME_SERIE_VALUE(gas_reserves, preset_demand, 2030)
      #
      # @example useage in inputs with USER_INPUT()
      #     TIME_SERIE_VALUE(gas_reserves, preset_demand, USER_INPUT())
      #
      def TIME_SERIE_VALUE(*keys)
        # TODO: make the following dynamic.
        key_1, key_2, year = keys.flatten
        scope.graph.time_curves[key_1.to_sym][key_2.to_sym][year.to_i] rescue nil
      end

      # Run multiple (update) queries.
      #
      # @example Multiple UPDATE statements inside one input
      #   EACH(
      #     UPDATE( foo, ... ),
      #     UPDATE( bar, ... )
      #   )
      #
      def EACH(*value_terms)
        value_terms.each do |value_term|
          value_term
        end
      end




      # == Remark about update_type
      #
      # Because ETmodel/flex return only numbers when pulling a slider, we can
      # define a default suffix for an input with the update_type attribute.
      #
      # A number 5 from an etmodel slider will be converted to "5%". So the
      # etmodel frontend displays a slider where you can update the growth
      # rate. When the user chooses 7% the slider actually only sends the
      # number  7 to the etengine. The ETengine/API if there is no suffix for
      # that slider, the api will append the one defined in  update_type
      # and send the "7%" to the GQL. The UPDATE function then derives from
      # that "7%" that it should increase the demand by 7% and not set the
      # demand to 7. Why: we once wanted the sliders to be flexible, so that
      # you can choose to use the slider with absolute, growth_rate and growth
      # per year. But simply got forgotten (either that we can, or that we
      # want to).
      #
      #
      # @example Basic syntax for update
      #   UPDATE( query_to_get_object, attr_name, new_value )
      #   UPDATE( L( foo ), demand, 100)
      #   UPDATE( L( foo ), demand, USER_INPUT() )
      #   UPDATE( L( foo ), demand, 100 - USER_INPUT() )
      #
      # @example
      #   UPDATE( L( foo ), demand,  5 ) # => demand becomes 5
      #   UPDATE( L( foo ), demand, "5") # => demand becomes 5
      #
      # @example multiple objects with the same number
      #   UPDATE( L( foo, bar, baz ), demand,  5 )
      #   # => demand of all node becomes 5
      #
      # @example multiple objects with a different number
      #   EACH(
      #    UPDATE( L( foo ), demand,   5 ),
      #    UPDATE( L( bar ), demand,  15 )
      #   )
      #
      # @example multiple objects based on USER_INPUT()
      #   EACH(
      #    UPDATE( L( foo ), demand, USER_INPUT() ),
      #    UPDATE( L( bar ), demand, 123 - USER_INPUT() )
      #   )
      #
      # @example multiple objects based on USER_INPUT() and other V()
      #   EACH(
      #    UPDATE( L( foo ), demand, USER_INPUT() ),
      #    UPDATE( L( bar ), demand, V(foo,demand) - USER_INPUT() )
      #   )
      #
      # @example WARNING: Updates run before the calculation
      #   # V(foo, demand) # => nil (no demand defined)
      #   UPDATE( L(foo), demand, "500" )
      #   # => 500. OK to assign an absolute value.
      #   UPDATE( L(foo), demand, "5%" )
      #   # => undefined behaviour. cannot increase nil
      #
      # @example WARNING: 2 inputs updating same attribute with absolute numbers
      #   input_1: UPDATE( L(foo), demand, "500" )
      #   input_2: UPDATE( L(foo), demand, "100" )
      #   # => foo gets value 100. but order of inputs can be reversed in another scenario. (pulling input_2 first).
      #
      def UPDATE(*value_terms)
        update_something_by(*value_terms) do |original_value, input_value|
          case update_strategy
          when :absolute then input_value
          when :relative_total
            original_value + (original_value * input_value)
          when :relative_per_year
            original_value * ((1.0 + input_value) ** scope.scenario.years)
          end
        end
      end

      # Same as UPDATE, but now the INPUT_VALUE() is expected to be factor,
      # that the user supplies.
      #
      # @example when foo has a preset_demand of 100.0
      #     UPDATE_WITH_FACTOR(V(foo), preset_demand, 1.1)
      #     # => foo gets a demand of 110.0
      #
      def UPDATE_WITH_FACTOR(*value_terms)
        update_something_by(*value_terms) do |original_value, input_value|
          original_value * input_value
        end
      end

      # Same as UPDATE, but forcefully behaving as the :absolute strategy.
      def UPDATE_ABSOLUTE(*value_terms)
        update_something_by(*value_terms) { |_, input_value| input_value }
      end

      # @private
      def update_something_by(*value_terms)
        input_value_proc = value_terms.pop
        attribute_name   = value_terms.pop
        objects          = value_terms.flatten.compact

        scope.update_collection = objects # for UPDATE_COLLECTION()
        objects.each do |object|
          object = object.query if object.respond_to?(:query)

          if object
            scope.update_object = object # for UPDATE_OBJECT()
            input_value    = input_value_proc.respond_to?(:call) ? input_value_proc.call : input_value_proc
            input_value    = input_value.first if input_value.is_a?(::Array)
            original_value = object[attribute_name]

            if original_value.is_a?(Numeric)
              original_value = original_value.to_f
            elsif original_value.nil?
              original_value = 0.0
            end

            value = yield original_value, input_value

            update_element_with(object, attribute_name, value)
          else
            # this will not execute...
            raise "UPDATE: objects not found: #{value_terms}"
          end
        end
      ensure
        scope.update_collection = nil
        scope.update_object = nil
      end

      # @private
      def update_element_with(object, attribute_name, value)
        object.send "#{attribute_name}=", value
      end

      # Private: at the moment only takes care of percentages and absolute numbers.
      #
      def input_factor
        if scope.update_type&.include?('%')
          100.0
        else
          1.0
        end
      end

      # Private:
      def big_decimal(n)
        scope.big_decimal(n)
      end

      # The update strategy derived from the input value passed to GQL
      #
      #   "3"   # => :absolute
      #   "3%"  # => :relative_total
      #   "3%y" # => :relative_per_year
      #
      def update_strategy
        case scope.update_type
        when '%y' then :relative_per_year
        when '%'  then :relative_total
        else           :absolute
        end
      end


      # The numeric value of the slider.
      #
      # The input value that is passed to the gql might be "3", "3%" or
      # "3%y". USER_INPUT() returns different numbers for different update
      # types, see examples.
      #
      # @example Absolute value "3"
      #   USER_INPUT() # => 3.0
      #
      # @example Growth rate "3%"
      #   USER_INPUT() # => 0.03
      #
      # @example Growth rate "3%y"
      #   USER_INPUT() # => 0.03
      #
      # @example To get the value of the input:
      #   USER_INPUT()
      #
      # @example To get the remainder:
      #   100 - USER_INPUT()
      #
      # @example Combining with values of another qernel object:
      #   V(foo, demand) - USER_INPUT()
      #
      def USER_INPUT()
        input = scope.input_value

        if input.is_a?(Numeric)
          input / input_factor
        else
          input
        end
      end

      # Public: Given the +key+ for an input, INPUT_VALUE retrieves the value
      # of that input in the following precedence:
      #
      #   * User-specified value,
      #   * Automatically balanced value,
      #   * Input start value.
      #
      # A Gql::NoSuchInputError is raised if no input has the given +key+.
      #
      # For example:
      #
      #   INPUT_VALUE('agriculture_geothermal_share')
      #   # => 0.104
      #
      #   INPUT_VALUE('infinite_improbability_drive_share')
      #   # !! Gql::NoSuchInputError
      #
      # Returns a float.
      def INPUT_VALUE(key)
        unless input = Input.get(key.to_s)
          raise Gql::NoSuchInputError.new(key.to_s)
        end

        scope.gql.scenario.input_value(input)
      end

      # UPDATE_OBJECT() Access currently updated object. It refers to the
      # object that is updated.
      #
      # Because the value that is retrieved is dynamically retrieved we have
      # to wrap it inside a block: -> {}.
      #
      # Remember that GQL goes from inside out, UPDATE_OBJECT() is
      # evaluated before UPDATE(...). UPDATE_OBJECT() would be nil. By
      # wrapping it inside -> {} we tell UPDATE that it should evaluate that
      # block after everything is assigned.
      #
      # @example Incrementing demands of multiple objects
      #   UPDATE( L( foo, bar, baz ), demand, -> {V(UPDATE_OBJECT(), demand) + USER_INPUT() })
      #   # equivalent to:
      #   EACH(
      #     UPDATE( L( foo ), demand, -> {V(foo, demand) + USER_INPUT()}),
      #     UPDATE( L( bar ), demand, -> {V(bar, demand) + USER_INPUT()}),
      #     ...
      #   )
      #
      def UPDATE_OBJECT()
        scope.update_object
      end

      # All objects in the UPDATE statement (the first part of UPDATE()).
      #
      # Example
      #
      #   UPDATE( L( foo, bar, baz ), demand, -> {
      #     SUM(V(UPDATE_COLLECTION(),demand)) - V(UPDATE_OBJECT(), demand)
      #   })
      #
      # Above statement updates the demand of foo, bar, baz with the remainder. Doesnt make sense but that's what would happen:
      #
      #   1. start: foo: 200, bar: 300, baz: 500
      #   2. updating foo: (200 + 300 + 500) - 200 => foo: 800
      #   3. updating bar: (800 + 300 + 500) - 300 => bar: 1300
      #   4. updating baz: (800 + 1300 + 500) - 500 => baz: 2100
      #
      def UPDATE_COLLECTION()
        scope.update_collection || []
      end

      # Updates FCE values.
      #
      # @example
      #      UPDATE_FCE( coal, australia, USER_INPUT() / 100)
      #      # equivalent
      #      UPDATE_FCE( CARRIER(coal), "australia", USER_INPUT() / 100)
      #
      def UPDATE_FCE(carrier, origin, user_input)
        carrier = carrier.first if carrier.is_a?(Array)
        carrier = carrier.key   if carrier.is_a?(Qernel::Carrier)

        scope.graph.plugin(:fce).update(carrier, origin, user_input)
      end
    end

  end
end
