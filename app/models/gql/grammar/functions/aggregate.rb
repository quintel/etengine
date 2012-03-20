module Gql::Grammar
  module Functions
    module Aggregate

      def NEG(*args)
        args.flatten!
        args.map!{|a| -a }
      end

      def AVG(values, arguments, scope = nil)
        SUM(values, nil) / COUNT(values, nil)
      end

      def SUM(*args)
        args.flatten!
        args.compact!
        args.inject(0) {|h,v| h + v }
      end
      
      def PRODUCT(*args)    
        args.flatten!
        args.compact!
        args.inject(1) {|total,value| total = total * value}
      end

      # DIVIDE(1,2) #=> 0.5
      # DIVIDE(1,2,3,4) #=> 0.5 # only takes the first two numbers
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
