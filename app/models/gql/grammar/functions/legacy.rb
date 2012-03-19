module Gql::Grammar
  module Functions
    module Legacy

      def replace_gql_with_ruby_brackets(attr_name)
        if attr_name.include?('[')
          attr_name.strip!
          attr_name.gsub!('[','(')
          attr_name.gsub!(']',')')
          attr_name
        else
          attr_name.tap(&:strip!)
        end
      end

      def ALL(*keys)
        scope.all_converters
      end

      def FILTER(converters, filter_name, scope)
        inst_eval = replace_gql_with_ruby_brackets(filter_name.first)
        flatten_uniq(converters.tap(&:flatten!).select{|c| c.query.instance_eval(inst_eval) })
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

      def CHILDREN(*converters)
        flatten_uniq(converters.tap(&:flatten!).map{|c| c.converter.children})
      end

      def PARENTS(*converters)
        flatten_uniq(converters.tap(&:flatten!).map{|c| c.converter.parents})
      end
  
      def INTERSECTION(*keys)
        keys.first.flatten & keys.last.flatten
      end

      def EXCLUDE(first, last)
        first.flatten - last.flatten
      end

      def INVALID_TO_ZERO(*keys)
        is_invalid = Proc.new {|v| v.nil? || (v.respond_to?(:nan?) && v.nan?) }

        if values.respond_to?(:map)
          values.tap(&:flatten!).map!{|v| is_invalid.call(v) ? 0 : v }
          values
        else
          is_invalid.call(values) ? 0 : v
        end
      end

      def MAX(*values)
        flatten_compact(values).max
      end

      def MIN(*values)
        flatten_compact(values).min
      end

      def ABS(*values)
        values = flatten_compact(values).map!{|v| v.abs if v }
        values
      end

      # NORMCDF(upper_boundary, mean, std_dev)
      def NORMCDF(*values)
        # lower_Boundary is always -Infinity
        upper_boundary, mean, std_dev = flatten_compact(values)
        Distribution::Normal.cdf( (upper_boundary.to_f - mean.to_f) / std_dev.to_f )
      end


      # SQRT(2) => [4]
      # SQRT(2,3) => [4,9]
      # SUM(SQRT(2,3)) => 13
      #
      def SQRT(*values)
        flatten_compact(values).map{|v| Math.sqrt(v) }
      end

      # LESS(1,2) => true
      # LESS(1,1) => false
      #
      def LESS(*values)
        a,b = values
        a < b rescue nil
      end

      # LESS_OR_EQUAL(1,1) => true
      #
      def LESS_OR_EQUAL(*values)
        a,b = values
        a <= b rescue nil
      end

      # GREATER(2,1) => true
      #
      def GREATER(*values)
        a,b = values
        a > b rescue false # FIX to make certain gqueries run with municipalities
        # nil would be better if the comparison fails
      end

      def GREATER_OR_EQUAL(*values)
        a,b = values
        a >= b rescue nil
      end

      def EQUALS(*values)
        a,b = values
        a == b
      end

      def NOT(*values)
        !(values.first == true)
      end

      def OR(*values)
        values.any?{|v| v == true }
      end

      # Is the value a number (and not nil or s'thing else).
      def IS_NUMBER(value)
        value.first.is_a?(Numeric)
      end

      # checks if value is nil
      def IS_NIL(value)
        value.first == nil
      end


     def NEG(*values)
        values = flatten_compact(values).map!{|v| v * -1.0}
        values.first
      end

      # Converts a value to another format. Know what you do!
      # Especially useful to write more readable Queries:
      #
      #   PRODUCT(0.15,100) => 15.0 (%)
      #   vs.
      #   UNIT(0.15;percentage) => 15.0 (%)
      #
      def UNIT(*values)
        first, second = values
        Unit.convert_to(first, second)
      end

      def INVERSE(*values)
        1.0 / values.first
      end

      def flatten_compact(arr)
        arr.tap(&:flatten!).tap(&:compact!)
      end

      def flatten_uniq(arr)
        arr.tap(&:flatten!).tap(&:uniq!)
      end
    end
  end
end
