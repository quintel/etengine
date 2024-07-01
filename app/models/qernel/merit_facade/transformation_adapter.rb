
# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Creates one or two must-run participants for the node.
    # One consumer and one producer.
    class TransformationAdapter < FlexAdapter
      def initialize(*)
        super
        @input_of_carrier = input_of_carrier
      end

      # Our participants! TODO: only add the ones necessary!
      def participant
        @participant ||= [consumer_participant, producer_participant]
      end

      def consumer_participant
        @consumer_participant ||= Merit::User.create(
          key: @node.key,
          load_profile: profile,
          total_consumption: @input_of_carrier
        )
      end

      def producer_participant
        @producer_participant ||= Merit::MustRunProducer.create(
          key: @node.key,
          load_profile: profile,
          full_load_hours: source_api.full_load_hours,
          output_capacity_per_unit: output_capacity_per_unit,
          marginal_costs: :null
        )
      end

      # Does not inject demand
      def inject!
        inject_curve!(:input) { consumer_participant.load_curve }
        inject_curve!(:output) { producer_participant.load_curve }
      end

      def input_of_carrier
        unless source_api.node.input(@context.carrier)
          raise "No acceptable consumption input for #{source_api.key}"
        end

        source_api.public_send(@context.carrier_named('input_of_%s'))
      end

      private

      def output_capacity_per_unit
        source_api.public_send(@context.carrier_named('%s_output_conversion')) *
          source_api.input_capacity
      end

      def profile
        @context.curves.curve(@config.group, @node)
      end
    end
  end
end
