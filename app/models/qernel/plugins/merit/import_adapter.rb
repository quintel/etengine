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

        # The marginal cost of the import producer is 1 EUR more than the the
        # most expensive participant.
        #
        # See https://github.com/quintel/merit/issues/143
        attrs[:marginal_costs]           = max_marginal_cost + 1.0
        attrs[:number_of_units]          = 1.0
        attrs[:output_capacity_per_unit] = @converter.electricity_output_capacity

        attrs
      end

      def producer_class
        ::Merit::DispatchableProducer
      end

      # Internal: Determines the marginal cost of the most expensive merit order
      # participant.
      #
      # Returns a Float.
      def max_marginal_cost
        types = @graph.plugin(:merit).participant_types

        mo_converters = @graph.converters.select do |conv|
          conf = conv.dataset_get(:merit_order)

          conf &&
            conf.type != :consumer &&
            conv.query.number_of_units > 0 &&
            types.include?(conf.type)
        end

        mo_converters.map do |conv|
          begin
            cost = conv.query.marginal_costs
            cost.nan? || cost == Float::INFINITY ? 0.0 : cost
          rescue
            0.0
          end
        end.max
      end
    end # ImportAdapter
  end # Merit
end
