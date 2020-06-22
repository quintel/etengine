module Gql::Runtime
  module Functions
    module Legacy

      def FILTER(collection, filter)
        flatten_uniq(collection.tap(&:flatten!).select do |el|
          el.query.instance_eval(filter.to_s)
        end)
      end


      def CHILDREN(*nodes)
        flatten_uniq(nodes.tap(&:flatten!).map{|c| c.node.rgt_nodes})
      end

      def PARENTS(*nodes)
        flatten_uniq(nodes.tap(&:flatten!).map{|c| c.node.lft_nodes})
      end

      # Returns the elements that are present in both the first and second arrays.
      #
      # Examples
      #
      #   INTERSECTION( V(1,2,3) , V(2,3,4) )
      #   # => [2, 3]
      #
      def INTERSECTION(*keys)
        keys.first.flatten & keys.last.flatten
      end

      # Returns an Array of elements of the first array excluding the second array.
      #
      # Examples
      #
      #   EXCLUDE( V(1,2,3) , V(2,3,4) )
      #   # => [1]
      #
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

      # Public: Rounds numeric value to a given precision.
      def ROUND(value, precision = 0)
        value.round(precision)
      end

      # Public: Returns the largest number less than or equal to numeric value.
      def FLOOR(value, precision = 0)
        value.floor(precision)
      end

      # Public: Returns the smallest number greater than or equal to numeric
      # value.
      def CEIL(value, precision = 0)
        value.ceil(precision)
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
        values[0] < values[1]
      rescue NoMethodError, ArgumentError
        # NoMethodError = values[0] was nil
        # ArgumentError = values[1] was nil
        nil
      end

      # LESS_OR_EQUAL(1,1) => true
      #
      def LESS_OR_EQUAL(*values)
        values[0] <= values[1]
      rescue NoMethodError, ArgumentError
        nil
      end

      # GREATER(2,1) => true
      #
      def GREATER(*values)
        values[0] > values[1]
      rescue NoMethodError, ArgumentError
        nil
      end

      def GREATER_OR_EQUAL(*values)
        values[0] >= values[1]
      rescue NoMethodError, ArgumentError
        nil
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

      # Public: Flattens any nested arrays into a single array with depth=1, removing nils.
      #
      # Equivalent to `array.flatten.compact` in Ruby.
      def FLATTEN(*values)
        flatten_compact(values)
      end

      def flatten_compact(arr)
        arr.map(&Kernel.method(:Array)).tap(&:flatten!).tap(&:compact!)
      end

      def flatten_uniq(arr)
        arr.map(&Kernel.method(:Array)).tap(&:flatten!).tap(&:uniq!)
      end
    end
  end
end
