module Qernel::Plugins
  module Merit
    # Implements behaviour specific to the import interconnector.
    class ImportAdapter < ProducerAdapter
      def inject!
        super

        elec_link = target_api.converter.output(:electricity).links.first

        if elec_link.link_type == :flexible
          # We need to override the calculation of the flexible link and set the
          # demand explicitly.
          elec_link.dataset_set(:value, target_api.demand)
          elec_link.dataset_set(:calculated, true)
        end
      end

      private

      def producer_class
        ::Merit::DispatchableProducer
      end

      def producer_attributes
        attrs = super

        attrs.delete(:marginal_costs)

        attrs[:cost_curve] = ::Merit::Curve.new(
          @graph.carrier(:imported_electricity).cost_curve
        )

        attrs
      end

      def marginal_costs
        0.0
      end

      def output_capacity_per_unit
        source_api.electricity_output_capacity
      end

      def flh_capacity
        source_api.electricity_output_capacity
      end
    end # ImportAdapter
  end # Merit
end
