# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Represents a Fever participant which will provide energy needed to meet
    # demand.
    class ProducerAdapter < Adapter
      include Attributes
      include CarrierHelpers
      include Inject

      # Public: Returns an appropriate adapter class to represent the given
      # node in Fever.
      #
      # Returns an Adapter class.
      def self.factory(node, _context)
        if node.key.to_s.include?('hybrid')
          HHPAdapter
        elsif node.dataset_get(:fever).efficiency_based_on
          VariableEfficiencyProducerAdapter
        else
          self
        end
      end

      def participant
        @participant ||=
          if @config.defer_for&.positive?
            Fever::DeferrableActivity.new(
              producer, share: share, expire_after: @config.defer_for
            )
          else
            Fever::Activity.new(producer, share: share)
          end
      end

      def inject!
        inject_demand!
        inject_curve!(:output) { participant.producer.output_curve.to_a }
        inject_input_curves!
      end

      def producer
        if (st = @node.dataset_get(:storage)) && st.volume.positive?
          Fever::BufferingProducer.new(
            capacity, reserve,
            input_efficiency: input_efficiency
          )
        else
          Fever::Producer.new(capacity, input_efficiency: input_efficiency)
        end
      end

      # Public: Returns if this adapter has any units installed.
      def installed?
        @node.number_of_units.positive?
      end

      private

      # Internal: The Fever participant is an alias of a producer in another
      # group; fetch it!
      def aliased_adapter
        alias_group = @context.plugin.group(
          @context.graph.node(@config.alias_of).dataset_get(:fever).group
        )

        alias_group.adapters.detect do |adapter|
          adapter.node.key == @config.alias_of
        end
      end
    end
  end
end
