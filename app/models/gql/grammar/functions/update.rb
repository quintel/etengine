module Gql::Grammar
  module Functions
    module Update

      def TIME_SERIE_VALUE(*keys)
        converter_id, time_curve_key, year = keys.flatten
        scope.graph.time_curves[converter_id.to_i][time_curve_key.to_sym][year.to_i] rescue nil
      end

      # Run multiple (update) queries.
      #
      # Examples
      #
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

      # Its syntax is:
      # 
      # UPDATE(object(s),attribute,value)
      #
      def UPDATE(*value_terms)
        input_value_proc = value_terms.pop
        attribute_name   = value_terms.pop
        objects          = value_terms.flatten.compact

        scope.update_collection = objects # for UPDATE_COLLECTION()
        objects.each do |object|
          object = object.query if object.respond_to?(:query)

          if object
            scope.update_object = object # for UPDATE_OBJECT()

            input_value = input_value_proc.respond_to?(:call) ? input_value_proc.call : input_value_proc
            input_value = input_value.first      if input_value.is_a?(::Array)

            object[attribute_name] = case update_strategy
            when :absolute then input_value
            when :relative_total
              cur_value = big_decimal(object[attribute_name].to_s)
              cur_value + (cur_value * input_value)
            when :relative_per_year
              cur_value = big_decimal(object[attribute_name].to_s)
              cur_value * ((1.0 + input_value) ** scope.scenario.years)
            end.to_f
          else
            # this will not execute...
            raise "UPDATE: objects not found: #{value_terms}"
          end
        end
      ensure
        scope.update_collection = nil
        scope.update_object = nil
      end

      # Private: at the moment only takes care of percentages and absolute numbers.
      #
      def input_factor
        if scope.input_value.andand.include?('%')
          100.0
        else 
          1.0
        end
      end

      # Private: 
      def big_decimal(n)
        scope.big_decimal(n)
      end

      # Private: 
      def update_strategy
        input = scope.input_value
        if input.is_a?(::String)
          if input.include?('%y') 
            :relative_per_year
          elsif input.include?('%') 
            :relative_total
          else
            :absolute
          end
        else
          :absolute
        end
      end

      def USER_INPUT()
        input = scope.input_value
        input_float = if input.is_a?(::String)
          # We need to use BigDecimal for pretty numbers (try in irb: 1.15 * 100.0)
          big_decimal(input)
        else
          input
        end
        input_float / input_factor
      end

      def UPDATE_OBJECT()
        scope.update_object
      end

      def UPDATE_COLLECTION()
        scope.update_collection || []
      end
    end

  end
end