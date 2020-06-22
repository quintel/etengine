# frozen_string_literal: true

module Qernel
  # Represents a node whose number of units is dynamically calculated based
  # on the NoU of a parent and the share of the link between the two.
  #
  # For example, [Child] will have number_of_units=6.0
  #
  #   +-----------------+                    +-------+
  #   | Parent (nou=20) | <- (share: 0.3) <- | Child |
  #   +-----------------+                    +-------+
  class InheritableNouNodeApi < NodeApi
    def number_of_units
      fetch(:number_of_units, false) do
        raise(InvalidParents, self) if node.output_links.length != 1

        units = nou_parent.node_api.number_of_units

        units && units *
          nou_link.share *
          nou_link.lft_input.conversion
      end
    end

    def number_of_units=(_)
      raise(
        NotImplementedError,
        'Cannot set number of units on an inheritable number-of-units ' \
        "node; set it on the parent (#{ nou_parent.key }) instead."
      )
    end

    private

    def nou_link
      node.output_links.first
    end

    def nou_parent
      nou_link.lft_node
    end

    # Raised when trying to create an InheritableNouNodeApi on a node
    # which does not have a parent.
    class InvalidParents < RuntimeError
      def initialize(api)
        @api = api
        @node = api.node
      end

      def message
        links = @node.output_links.length

        "Cannot use #{ @api.class.name.split('::').last } on a " \
        "node with #{ links } parents (#{ @node.key })"
      end
    end
  end
end
