module Qernel::Plugins
  module Merit
    # Implements behaviour specific to the import interconnector.
    class ImportAdapter < ProducerAdapter
      def inject!
        super

        elec_link = @converter.converter.output(:electricity).links.first

        if elec_link.link_type == :flexible
          # We need to override the calculation of the flexible link and set
          # set the demand explicitly.
          elec_link.dataset_set(:value, @converter.demand)
          elec_link.dataset_set(:calculated, true)
        end
      end

      private

      def producer_class
        ::Merit::DispatchableProducer
      end

      def marginal_costs
        @graph.carrier(:imported_electricity).cost_per_mj * 3600
      end

      def output_capacity_per_unit
        @converter.electricity_output_capacity
      end

      def flh_capacity
        @converter.electricity_output_capacity
      end
    end # ImportAdapter
  end # Merit
end
