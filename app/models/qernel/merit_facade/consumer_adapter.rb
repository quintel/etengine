# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Converts a Qernel::Node to a Merit user.
    class ConsumerAdapter < Adapter
      def self.factory(node, context)
        case context.node_config(node).subtype
        when :pseudo
          PseudoConsumerAdapter
        when :consumption_loss
          ConsumptionLossAdapter
        when :electricity_loss
          ElectricityLossAdapter
        else
          self
        end
      end

      def initialize(*)
        super
        @input_of_carrier = input_of_carrier
      end

      def participant
        @participant ||=
          if @config.group.to_s.starts_with?('self:')
            Merit::User.create(
              key: @node.key,
              load_curve: @context.curves.curve(@config.group, @node)
            )
          else
            Merit::User.create(
              key: @node.key,
              load_profile: consumption_profile,
              total_consumption: @input_of_carrier
            )
          end
      end

      def inject!
        inject_curve!(:input) { @participant.load_curve }
      end

      def input_of_carrier
        unless source_api.node.input(@context.carrier)
          raise "No acceptable consumption input for #{source_api.key}"
        end

        source_api.public_send(@context.carrier_named('input_of_%s'))
      end

      def installed?
        @input_of_carrier.positive?
      end

      private

      def consumption_profile
        @context.curves.curve(@config.group, @node)
      end
    end
  end
end
