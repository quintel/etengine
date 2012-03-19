module Gql::Grammar
  module Functions
    module Update

      def TIME_SERIE_VALUE(*keys)
        converter_id, time_curve_key, year = keys.flatten
        scope.graph.time_curves[converter_id.to_i][time_curve_key.to_sym][year.to_i] rescue nil
      end

      def EACH(*value_terms)
        # value_terms.each do |value_term|
        #   value_term
        # end
      end

      # Its syntax is:
      # 
      # UPDATE(object(s),attribute,value)
      #
      def UPDATE(*value_terms)
        input_value    = value_terms.pop
        attribute_name = value_terms.pop
        objects = value_terms.compact

        scope.update_collection = objects # for UPDATE_COLLECTION()
        objects.each do |object|
          object = object.query if object.respond_to?(:query)

          if object
            scope.update_object = object # for UPDATE_OBJECT()

            object[attribute_name] = case update_strategy(scope)
            when :absolute then input_value
            when :relative_total
              cur_value = big_decimal(object[attribute_name].to_s)
              cur_value + (cur_value * input_value)
            when :relative_per_year
              cur_value = big_decimal(object[attribute_name].to_s)
              cur_value * ((1.0 + input_value) ** ::Current.scenario.years)
            end.to_f
          else
            raise "UPDATE: objects not found: #{value_terms}"
          end
        end
      ensure
        scope.update_collection = nil
        scope.update_object = nil
      end

      # at the moment only takes care of percentages and absolute numbers.
      #
      def input_factor(scope)
        if scope.input_value.andand.include?('%')
          100.0
        else 
          1.0
        end
      end

      def big_decimal(n)
        # DEBT: Revert this back
        # BigDecimal(input)
        n.to_f
      end

      def update_strategy(scope)
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
        input_float / input_factor(scope)
      end

      def UPDATE_OBJECT()
        scope.update_object
      end

      def UPDATE_COLLECTION()
        scope.update_collection || []
        # if scope.update_collection
        #   scope.update_collection
        # else
        #   raise "GQL SELF() has to be inside UPDATE and a valid object has to be defined"
        # end
      end
    end

  end
end