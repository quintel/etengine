module Qernel::Plugins
  module Merit
    class CurtailmentAdapter < FlexAdapter
      def inject!
        elec_link = target_api.converter.input(:electricity).links.first

        # Figure out the electricity output efficiency of the HV network;
        # curtailment needs to be reduced by exactly this amount to prevent
        # unwanted import.
        efficiency = elec_link.output.conversion
        demand     = participant.production(:mj) * efficiency

        if elec_link.link_type == :inversed_flexible
          # We need to override the calculation of an inversed flexible link
          # and set the demand explicitly.
          elec_link.dataset_set(:value, demand)
          elec_link.dataset_set(:calculated, true)
        end

        target_api.demand = demand
      end

      private

      def producer_attributes
        attrs = super

        if @config.group == :curtailment
          attrs[:input_capacity_per_unit]  = Float::INFINITY
          attrs[:output_capacity_per_unit] = Float::INFINITY
        else
          # TODO Can this be set in FlexAdapter?
          attrs[:input_capacity_per_unit] =
            @converter.input_capacity ||
            @converter.output_capacity
        end

        attrs[:number_of_units] = 1.0

        attrs
      end
    end # CurtailmentAdapter
  end # Merit
end
