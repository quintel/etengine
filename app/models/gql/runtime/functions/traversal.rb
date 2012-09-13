module Gql::Runtime
  module Functions
    # @example Example used in description
    #
    #   Example Graph
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
          link = lft.input_links.detect{|l| l.rgt_converter == rgt.converter}
          link ||= lft.output_links.detect{|l| l.lft_converter == rgt.converter}
          link
        end
      end

      # @example All links on a converter
      #   LINKS(L(foo))
      #   # => [foo->gas_1, foo->gas_2, loss1->foo, heat1->foo]
      #
      # @example All output links with a constraint
      #   LINKS(L(foo), "share?")
      #   LINKS(L(foo), "flexible?")
      #   LINKS(L(foo), "flexible? && share >= 1.0")
      #
      # @example All links of a given carrier/slot
      #    LINKS(OUTPUT_SLOTS(foo, heat)) # => [heat->foo]
      #
      # @example Links of multiple converters
      #   LINKS(L(foo, bar))
      #
      def LINKS(value_terms, arguments = nil)
        links_for(value_terms, arguments)
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
        flatten_uniq converters.compact.map{|c| carrier ? c.input(carrier.to_sym) : c.inputs}
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
      def INPUT_LINKS(value_terms, arguments = nil)
        links_for(value_terms, arguments, [:input_links, :links])
      end

      # @example All output links
      #   OUTPUT_LINKS(L(foo))
      #
      # @example All output links with a constraint
      #   OUTPUT_LINKS(L(foo), "share?")
      #   OUTPUT_LINKS(L(foo), "flexible?")
      #   OUTPUT_LINKS(L(foo), "flexible? && share >= 1.0")
      #
      # @example All output links of a given carrier/slot
      #    OUTPUT_LINKS(OUTPUT_SLOTS(foo, heat)) # => [heat->foo]
      #
      # @example Output links of multiple converters
      #   OUTPUT_LINKS(L(foo, bar))
      #
      def OUTPUT_LINKS(value_terms, arguments = nil)
        links_for(value_terms, arguments, [:output_links, :links])
      end

      #######
      private
      #######

      # Internal: Returns links from one or more Qernel objects.
      #
      # The `using` parameter allows you to provide an array of methods to try
      # in order to retrieve the links for each object. For example, when
      # looking for output links, you might use `[:output_links, :links]`.
      # Objects with an `output_links` method (Converter) would use that,
      # otherwise `links` will be used (Slot).
      #
      # `arguments` may contain a single string used to filter out
      # non-matching links.
      #
      # @example All links from two objects.
      #   links_for(L(converter_one, converter_two))
      #
      # @example Filtering
      #   links_for(L(converter_one), '! flexible?')
      #
      # @example Selecting only output links.
      #   links_for(L(converter_one), nil, [:output_links])
      #
      # @example Selecting output links, falling back to all links.
      #   links_for(L(converter_one, slot_one), nil, [:output_links, :links])
      #
      def links_for(value_terms, arguments = nil, using = [:links])
        value_terms.flatten

        links = flatten_uniq(value_terms).map! do |obj|
          if method = using.detect { |method| obj.respond_to?(method) }
            obj.public_send(method)
          end
        end

        links.compact!
        links.flatten!

        if arguments.present?
          filter = arguments.is_a?(Array) ? arguments.first : arguments
          links.select! { |link| link.instance_eval(filter.to_s) }
        end

        links
      end

    end # Traversal
  end # Functions
end # Gql::Runtime
