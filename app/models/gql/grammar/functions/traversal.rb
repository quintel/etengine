
module Gql::Grammar
  module Functions
    # @example Example used in description
    #
    #                   +---------------+        +--> gas_1
    #                   |               |        |
    #   loss1 <- (loss)-|   foo         |- (gas)-+--> gas_2
    #                   |               |
    #   heat1 <- (heat)-|  <Converter>  |- (oil)-+
    #                   |               |        +--> oil_1
    #                   +---------------+        
    #    
    module Traversal

      # ELEMENT_AT( SORT_BY(GROUP(electricity); demand), 0) => converter with smallest demand
      def ELEMENT_AT(*converters)
        index = converters.last.to_i
        converters.flatten[index]
      end

      # Returns the first element of the array.
      #
      # Examples
      #
      #   LAST(V(1,2,3)) # => 3
      #   LAST(LOOKUP(foo, bar)) # => :bar
      #
      def LAST(*value_terms)
        value_terms.flatten.last
      end

      # Returns the last element of the array.
      #
      # Examples
      #
      #   LAST(V(1,2,3)) # => 1
      #   LAST(LOOKUP(foo, bar)) # => :foo
      #
      def FIRST(*value_terms)
        value_terms.flatten.first
      end

      # Returns the {Qernel::Link} that goes from the first to the second converter.
      #
      # LINK() performs a LOOKUP on the two keys.
      #
      # Examples
      #
      #   LINK( foo, bar ) => Qernel::Link
      #   # works in the other direction too
      #   LINK( bar, foo ) => Qernel::Link
      #
      def LINK(lft, rgt)
        lft,rgt = LOOKUP(lft, rgt).flatten
        if lft.nil? || rgt.nil?
          nil
        else
          link = lft.input_links.detect{|l| l.child == rgt.converter}
          link ||= lft.output_links.detect{|l| l.parent == rgt.converter}
          link
        end
      end

      
      # All links on both sides of a converter
      #
      # @example 
      #   LINKS(L(foo)) # => [foo->gas_1, foo->gas_2, loss1->foo, heat1->foo]
      #
      def LINKS(*value_terms)
        value_terms.flatten.compact.map(&:links).flatten
      end

      # Get the output (to the left) slots of converter(s). 
      #
      # @example All input slots
      #   OUTPUT_SLOTS(foo)           #=> [(loss)-foo, (heat)-foo]
      #   OUTPUT_SLOTS(L(foo))        #=> [(loss)-foo, (heat)-foo]
      #   OUTPUT_SLOTS(L(foo,bar))    #=> [(loss)-foo, (heat)-foo, ...]
      #
      # @example All input slots
      #   OUTPUT_SLOTS(foo, loss) #=> [(loss)-foo]
      #
      def OUTPUT_SLOTS(*args)
        carrier = args.pop if args.length > 1
        converters = LOOKUP(args).flatten
        flatten_uniq converters.compact.map{|c| carrier ? c.output(carrier.to_sym) : c.outputs}
      end

      # Get the input (to the right) slots of converter(s). 
      #  
      # @example All input slots
      #   INPUT_SLOTS(foo) #=> [foo-(gas), foo-(oil)]
      #
      # @example All input slots
      #   INPUT_SLOTS(foo, gas) #=> [foo-(gas)]
      #
      def INPUT_SLOTS(*args)
        carrier = args.pop if args.length > 1
        converters = LOOKUP(args).flatten
        flatten_uniq converters.compact.map{|c| carrier ? c.input(carrier.to_sym) : c.outputs}
      end

      # @example All input links
      #   INPUT_LINKS(L(foo))
      #
      # @example All input links with a constraint
      #   INPUT_LINKS(L(foo), "share?")
      #   INPUT_LINKS(L(foo), "flexible?")
      #   INPUT_LINKS(L(foo), "flexible? && share >= 1.0")
      #
      # @example All input links of a given carrier/slot
      #    INPUT_LINKS(INPUT_SLOTS(foo, oil)) # => [foo->oil_1]
      #
      # @example Input links of multiple converters
      #   INPUT_LINKS(L(foo, bar))
      #
      def INPUT_LINKS(value_terms, arguments = [])
        links = flatten_uniq(value_terms.tap(&:flatten!)).map do |obj|
          if obj.respond_to?(:input_links) # it's a converter
            obj.input_links
          elsif obj.respond_to?(:links) # it's a slot
            obj.links
          end
        end
        links.flatten!

        if arguments.present?
          inst_eval = arguments.is_a?(Array) ? arguments.first : arguments
          links.select!{|link| link.instance_eval(inst_eval.to_s) } 
        end
        links
      end

      # @example All input links
      #   OUTPUT_LINKS(L(foo))
      #
      # @example All input links with a constraint
      #   OUTPUT_LINKS(L(foo), "share?")
      #   OUTPUT_LINKS(L(foo), "flexible?")
      #   OUTPUT_LINKS(L(foo), "flexible? && share >= 1.0")
      #
      # @example All output links of a given carrier/slot
      #    OUTPUT_LINKS(OUTPUT_SLOTS(foo, heat)) # => [heat->foo]
      #
      # @example Input links of multiple converters
      #   OUTPUT_LINKS(L(foo, bar))
      #
      def OUTPUT_LINKS(value_terms, arguments = [])
        links = flatten_uniq(value_terms.tap(&:flatten!)).map do |obj|
          if obj.respond_to?(:output_links) # it's a converter
            obj.input_links
          elsif obj.respond_to?(:links) # it's a slot
            obj.links
          end
        end
        links.flatten!

        if arguments.present?
          inst_eval = arguments.is_a?(Array) ? arguments.first : arguments
          links.select!{|link| link.instance_eval(inst_eval.to_s) } 
        end
        links
      end
    end
  end
end