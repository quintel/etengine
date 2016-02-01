module Qernel::Plugins
  module Merit
    class CurtailmentAdapter < FlexAdapter
      def inject!
        target_api.demand = participant.production(:mj)
      end

      private

      def producer_attributes
        attrs = super

        if @config.group == :curtailment
          attrs[:input_capacity_per_unit]  = Float::INFINITY
          attrs[:output_capacity_per_unit] = Float::INFINITY
        else
          attrs[:input_capacity_per_unit] =
            attrs[:output_capacity_per_unit] =
            @converter.network_capacity_available_in_mw
        end

        attrs[:number_of_units] = 1.0

        attrs
      end
    end # CurtailmentAdapter
  end # Merit
end
