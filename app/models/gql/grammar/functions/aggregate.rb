module Gql::Grammar
  module Functions
    module Aggregate

      # Returns how many (non-nil) values
      #
      # Examples
      #
      #   COUNT(1)       # => 1
      #   COUNT(1,2)     # => 2
      #   COUNT(1,nil,2) # => 2
      #
      def COUNT(*values)
        flatten_compact(values).length
      end

      # Returns the *first* number as a negative
      #
      # Examples
      #
      #   NEG(2)     # => -2
      #   NEG(1,2,3) # => -1
      #
      # Change Request:
      #
      # Following behaviour makes more sense
      #
      #   NEG(2)     # => -2
      #   NEG(1,2,3) # => [-1, -2, -3]
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
      # Examples
      #
      #   AVG(1,2)   # => 1.5
      #   AVG(1,2,3) # => 2
      #   AVG(1,nil,nil,2)   # => 1.5
      #
      def AVG(*values)
        values.flatten!
        values.compact!
        SUM(values) / COUNT(values)
      end

      # Returns the sum of all numbers (ignores nil values).
      #
      # Examples
      #
      #   SUM(1,2)   # => 3
      #   SUM(1,2,3) # => 6
      #   SUM(1)     # => 1
      #   SUM(1,nil) # => 1
      #
      def SUM(*args)
        args.flatten!
        args.compact!
        args.inject(0) {|h,v| h + v }
      end
      
      # Multiplies all numbers (ignores nil values).
      #
      # Examples
      #
      #   PRODUCT(1,2)   # => 2 (1*2)
      #   PRODUCT(1,2,3) # => 6 (1*2*3)
      #   PRODUCT(1)     # => 1
      #   PRODUCT(1,nil) # => 1
      #
      def PRODUCT(*args)    
        args.flatten!
        args.compact!
        args.inject(1) {|total,value| total = total * value}
      end

      
      # Divides the first with the second.
      #
      # Examples
      #
      #   DIVIDE(1,2) #=> 0.5
      #   DIVIDE(1,2,3,4) #=> 0.5 # only takes the first two numbers
      #
      def DIVIDE(*values)
        a,b = values.tap(&:flatten!)

        if a == 0.0 || a.nil?
          0.0
        else
          a / b
        end
      end

    end
  end
end
