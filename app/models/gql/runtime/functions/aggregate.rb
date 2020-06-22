module Gql::Runtime
  module Functions
    module Aggregate

      # Returns how many values. Removes nil values, but does
      # not remove duplicates.
      #
      # @example Basic useage
      #   COUNT(1)              # => 1
      #   COUNT(1,2)            # => 1
      #
      # @example with nodes
      #   COUNT(L(foo,bar))     # => 2
      #
      # @example multiple LOOKUPs (does not remove duplicates)
      #   COUNT(L(foo,bar), L(foo))     # => 3
      #   # However: (LOOKUP removes duplicates)
      #   COUNT(L(foo,bar,foo), L(f))   # => 2
      #
      # @example nil values are removed (do not count)
      #   COUNT(1,nil,2) # => 2
      #
      # @param [Numeric,Array] *values one or multiple values or arrays
      # @return [Numeric] The element count.
      #
      def COUNT(*values)
        values.flatten!
        values.compact!

        values.length
      end

      # Returns the *first* number as a negative
      #
      # @example
      #   NEG(2)            # => -2
      #   NEG(1,2,3)        # => -1
      #
      # Change Request:
      #
      # Following behaviour makes more sense
      #
      #   NEG(2)            # => -2
      #   NEG(1,2,3)        # => [-1, -2, -3]
      #
      # @param [Numeric,Array] *values one or multiple values or arrays
      # @return [Numeric] The average of the *first* value
      #
      def NEG(*args)
        args.flatten!
        args.map!{|a| -a }
        # args.length == 1 ? args.first : args
        # above is what i'd expect, below is legacy behaviour.
        args.first
      end

      # Returns the average of all number (ignores nil values).
      #
      # @example
      #   AVG(1,2)          # => 1.5
      #   AVG(1,2,3)        # => 2
      #   AVG(1,nil,nil,2)  # => 1.5
      #
      # @param [Numeric,Array] *values one or multiple values or arrays
      # @return [Numeric] The average of all values
      #
      def AVG(*values)
        values.flatten!
        values.compact!
        SUM(values) / COUNT(values)
      end

      # Returns the sum of all numbers (ignores nil values).
      #
      # @example
      #   SUM(1,2)          # => 3
      #   SUM(1,2,3)        # => 6
      #   SUM(1)            # => 1
      #   SUM(1,nil)        # => 1
      #
      # @param [Numeric,Array] *values one or multiple values or arrays
      # @return [Numeric] The average of all values
      #
      def SUM(*args)
        args.flatten!
        args.compact!
        args.sum
      end

      # Multiplies all numbers (ignores nil values).
      #
      # @example
      #   PRODUCT(1,2)     # => 2 (1*2)
      #   PRODUCT(1,2,3)   # => 6 (1*2*3)
      #   PRODUCT(1)       # => 1
      #   PRODUCT(1,nil)   # => 1
      #
      # @param [Numeric,Array] *values one or multiple values or arrays
      # @return [Numeric] The average of all values
      #
      def PRODUCT(*args)
        args.flatten!
        args.compact!
        args.inject(1) {|total,value| total = total * value}
      end


      # Divides the first with the second.
      #
      # @example
      #   DIVIDE(1,2)      # => 0.5
      #   DIVIDE(1,2,3,4)  # => 0.5 # only takes the first two numbers
      #   DIVIDE([1,2])    # => 0.5
      #   DIVIDE([1],[2])  # => 0.5
      #   DIVIDE(1,2)      # => 0.5
      #
      # @example Watch out doing normal arithmetics (outside DIVIDE)
      #   DIVIDE(2,3)      # => 0.66
      #   # (divideing integers gets you elimentary school output. 2 / 3 = 0 with remainder 2)
      #   2 / 3            # => 0
      #   2 % 3            # => 2 # % = modulo (what is the remainder)
      #   2.0 / 3          # => 0.66 If one number is a float it works as expected
      #   2 / 3.0          # => 0.66 If one number is a float it works as expected
      #
      # @example Exceptions
      #   DIVIDE(nil, 1)   # => 0.0
      #   DIVIDE(0.0, 1)   # => 0.0 and not NaN
      #   DIVIDE(0,   1)   # => 0.0 and not NaN
      #   DIVIDE(1.0,0.0)  # => Infinity
      #
      # @param [Numeric,Array] *values one or multiple values or arrays. But only the first two are taken.
      # @return [Numeric] The average of all values
      #
      def DIVIDE(*values)
        a, b = values.tap(&:flatten!)

        if a.nil? || b.nil? || a.zero? || b.zero?
          0.0
        else
          a.to_f / b
        end
      end
    end
  end
end
