module Qernel::Plugins
  module Merit
    class ImportAdapter < Adapter
      def inject!
        elec_link = @converter.converter.output(:electricity).links.first
        demand    = participant.production(:mj)

        if elec_link.link_type == :flexible
          # We need to override the calculation of the flexible link and set
          # set the demand explicitly.
          elec_link.dataset_set(:value, demand)
          elec_link.dataset_set(:calculated, true)
        end

        @converter.demand = demand
      end

      private

      def producer_attributes
        attrs = super

        # Fake high marginal cost to ensure that import is sorted last. Merit
        # will ignore this price.
        #
        # TODO Remove, and add a way to force a participant to be last.
        attrs[:marginal_costs]           = 999_999_999_999.99
        attrs[:number_of_units]          = 1.0
        attrs[:output_capacity_per_unit] = @converter.electricity_output_capacity

        attrs
      end

      def producer_class
        ::Merit::DispatchableProducer
      end
    end # ImportAdapter
  end # Merit
end
