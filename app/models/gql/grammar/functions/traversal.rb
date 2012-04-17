module Gql::Grammar
  module Functions
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

      def LINKS(*value_terms)
        value_terms.flatten.compact.map(&:links).flatten
      end

      #
      #
      # Examples
      #
      #   OUTPUT_SLOTS(converter_key, carrier)
      #   OUTPUT_SLOTS(LOOKUP(converter_key), carrier)
      #
      def OUTPUT_SLOTS(*args)
        carrier = args.pop
        converters = LOOKUP(args).flatten
        flatten_uniq converters.compact.map{|c| carrier ? c.output(carrier.to_sym) : c.outputs}
      end

      # INPUT_SLOTS(converter_key; carrier)
      # INPUT_SLOTS(V(converter_key); carrier)
      #
      def INPUT_SLOTS(*args)
        carrier = args.pop
        converters = LOOKUP(args).flatten
        flatten_uniq converters.compact.map{|c| carrier ? c.input(carrier.to_sym) : c.outputs}
      end

      def INPUT_LINKS(value_terms, arguments = [])
        links = flatten_uniq(value_terms.tap(&:flatten!).map(&:input_links))
        if arguments.present?
          inst_eval = arguments.is_a?(Array) ? arguments.first : arguments
          links.select!{|link| link.instance_eval(inst_eval.to_s) } 
        end
        links
      end

      def OUTPUT_LINKS(value_terms, arguments = [])
        links = flatten_uniq(value_terms.tap(&:flatten!).map(&:output_links))
        if arguments.present?
          inst_eval = arguments.is_a?(Array) ? arguments.first : arguments
          links.select!{|link| link.instance_eval(inst_eval.to_s) } 
        end
        links
      end
    end
  end
end