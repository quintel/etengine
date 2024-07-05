
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

      # One or two participants
      def participant
        @participant ||= if consumer? && producer?
          [consumer_participant, producer_participant]
        else
          consumer? ? consumer_participant : producer_participant
        end
      end

      def consumer?
        @input_of_carrier&.positive?
      end

      def producer?
        output_capacity_per_unit.positive?
      end

      def consumer_participant
        @consumer_participant ||= Merit::User.create(
          key: "#{@node.key}_consumer",
          load_profile: profile,
          total_consumption: @input_of_carrier
        )
      end

      def producer_participant
        @producer_participant ||= Merit::MustRunProducer.new(
          key: "#{@node.key}_producer",
          load_profile: profile,
          full_load_hours: source_api.full_load_hours,
          output_capacity_per_unit: output_capacity_per_unit,
          marginal_costs: :null,
          number_of_units: target_api.number_of_units
        )
      end

      def installed?
        producer? || consumer?
      end

      # Does not inject demand, as this node is expected to be a preset demand node
      # TODO: check if it should inject for carrier specfic
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
