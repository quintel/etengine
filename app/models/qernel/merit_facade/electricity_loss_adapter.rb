# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A special case of consumer used when representing loss within the
    # electricity network. In this we need to determine the demand from a method
    # on GraphApi, and set the demand on the node and sole incoming link after
    # the calculation is done. This is required in order for Slot::LinkBased to
    # calculate the share of electricty.
    class ElectricityLossAdapter < ConsumerAdapter
      def inject!
        super

        production = @participant.production

        target_api.demand = production

        input_link.value = production
        input_link.calculated = true
      end

      def input_of_carrier
        # HV loss node does not have an electricity input; use graph method
        # which compensates for export.
        @context.graph.query.electricity_losses_if_export_is_zero
      end

      private

      def input_link
        links = target_api.node.input(:loss).links

        if links.length != 1
          raise "Could not find single loss input on #{target_api.key} for " \
                "use by #{self.class.name} (found #{links.length} links)"
        end

        links.first
      end
    end
  end
end
