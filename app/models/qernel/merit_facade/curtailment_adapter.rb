# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sets up a Merit participant which will be used last, using any excess
    # energy not exported or assigned to flexibles.
    class CurtailmentAdapter < FlexAdapter
      def inject!
        super

        input_link = target_api.converter.input(@context.carrier).links.first
        demand     = participant.production(:mj)

        if @context.carrier == :electricity
          # Figure out the output efficiency of the network; curtailment needs
          # to be reduced by exactly this amount to prevent unwanted import.
          demand *= input_link.output.conversion
        end

        if input_link.link_type == :inversed_flexible
          # We need to override the calculation of an inversed flexible link
          # and set the demand explicitly.
          input_link.dataset_set(:value, demand)
          input_link.dataset_set(:calculated, true)
        end

        target_api.demand = demand
      end

      def installed?
        # Curtailment is always available as an consumer-of-last-resort.
        true
      end

      private

      def producer_attributes
        attrs = super

        if @config.group == :curtailment
          attrs[:input_capacity_per_unit]  = Float::INFINITY
          attrs[:output_capacity_per_unit] = Float::INFINITY
        else
          # TODO: Can this be set in FlexAdapter?
          attrs[:input_capacity_per_unit] =
            source_api.input_capacity ||
            source_api.output_capacity
        end

        attrs[:number_of_units] = 1.0

        attrs
      end
    end
  end
end
