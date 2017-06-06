# frozen_string_literal: true

module Qernel
  # Represents a converter whose number of units is dynamically calculated based
  # on the NoU of a parent and the share of the link between the two.
  #
  # For example, [Child] will have number_of_units=6.0
  #
  #   +-----------------+                    +-------+
  #   | Parent (nou=20) | <- (share: 0.3) <- | Child |
  #   +-----------------+                    +-------+
  class InheritableNouConverterApi < ConverterApi
    def number_of_units
      fetch(:number_of_units, false) do
        raise(InvalidParents, self) if converter.output_links.length != 1

        units = nou_parent.converter_api.number_of_units

        units && units *
          nou_link.share *
          nou_link.lft_input.conversion
      end
    end

    def number_of_units=(_)
      raise(
        NotImplementedError,
        'Cannot set number of units on an inheritable number-of-units ' \
        "converter; set it on the parent (#{ nou_parent.key }) instead."
      )
    end

    private

    def nou_link
      converter.output_links.first
    end

    def nou_parent
      nou_link.lft_converter
    end

    # Raised when trying to create an InheritableNouConverterApi on a converter
    # which does not have a parent.
    class InvalidParents < RuntimeError
      def initialize(api)
        @api = api
        @converter = api.converter
      end

      def message
        links = @converter.output_links.length

        "Cannot use #{ @api.class.name.split('::').last } on a " \
        "converter with #{ links } parents (#{ @converter.key })"
      end
    end
  end
end
