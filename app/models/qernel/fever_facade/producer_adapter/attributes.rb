# frozen_string_literal: true

module Qernel
  module FeverFacade
    class ProducerAdapter < Adapter
      # Calculates values used by Fever producers.
      module Attributes
        private

        # Internal: Calculates what share of the total heat demand will be
        # supplied by this producer.
        def share
          edge = @node.node.output(:useable_heat).edges.first

          if edge.lft_node.key.to_s.include?('aggregator')
            edge.lft_node.output(:useable_heat).edges.first.share
          else
            edge.share
          end
        end

        def output_efficiency
          slots = @node.node.outputs.reject(&:loss?)
          slots.any? ? slots.sum(&:conversion) : 1.0
        end

        def input_efficiency
          1.0 / @node.node.input(input_carrier).conversion
        end

        # Internal: The capacity of the Fever participant in each frame.
        #
        # Returns an arrayish.
        def capacity
          return total_value(:heat_output_capacity) unless @config.alias_of

          DelegatedCapacityCurve.new(
            total_value(:heat_output_capacity),
            aliased_adapter.participant.producer,
            input_efficiency
          )
        end

        # Internal: Creates a Reserve which can be used by a Fever participant
        # which will buffer energy in a reserve before it is needed.
        #
        # Returns a Merit::Flex::Reserve.
        def reserve
          volume  = total_value { @node.dataset_get(:storage).volume }
          reserve = Merit::Flex::SimpleReserve.new(volume)

          # Buffer starts full.
          reserve.add(0, volume)

          reserve
        end
      end
    end
  end
end
