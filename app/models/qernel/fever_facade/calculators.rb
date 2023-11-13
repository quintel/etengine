# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Class to set up all calculators for the group and define the shares of producers per consumer
    class Calculators
      def initialize(ordered_producers, ordered_consumers, context)
        @context = context
        @ordered_consumers = ordered_consumers
        @ordered_producers = ordered_producers

        # first build then refactor
        # make sure we can forget what we don't need
        setup_network
      end

      def calculators
        @calculators ||= matched_consumers.values.map do |consumer, activities|
          Fever::Calculator.new(consumer.participant, activities)
        end
      end

      def calculate_frame(frame)
        calculators.each { |calc| calc.calculate_frame(frame) }
      end

      # TODO: Is it in an array so that its faster? could also be a hash -> check what's optimal
      def matched_consumers
        @matched_consumers ||= @ordered_consumers.inject({}) do |consumers, consumer_node_key|
          consumers[consumer_node_key] = [
            adapter_for(consumer_node_key), # consumer
            [] # activities
          ]
          consumers
        end
      end

      # Sets up the adapters and matched consumers to create e network to intialize the calculators
      def setup_network
        @ordered_producers.each do |producer_node_key|
          producer = adapter_for(producer_node_key)

          producer_share = producer.share_in_group
          # verify this is correct behaviour. what happens with the share zero things in fever itsefl?
          next if producer_share.zero?

          # For each ordered consumer, check if an activity should be added to it's calculator
          @ordered_consumers.each do |consumer_node_key|
            # Check if the producer is either done or did not join in the first place
            # TODO: not just next, but we can break here! if the "next" above is correct
            next if producer_share.zero?

            consumer = @matched_consumers[consumer_node_key][0]

            # Another producer already filled up the whole consumer or there are no hh in consumer
            next if consumer.share_met == 1.0 || consumer.share_in_total.zero?

            # Now we calculate the share between this consumer and the producer.
            # The maximum share of buildings/houses the producer can supply to is:
            # The minimum of the share of houses the producers still has to deliver to,
            # and the share of houses/buldings the consumer represents, multiplied by
            # if other producers already met a piece of its demand.
            consumer_share = min(producer_share, (1.0 - consumer.share_met) * consumer.share_in_total)

            # Keep track on to how many housholds/buidlings the producer still needs to deliver
            producer_share -= consumer_share

            consumer_share_met_by_producer = consumer_share / consumer.share_in_total

            @matched_consumers[consumer_node_key][1] << producer.participant(consumer_share_met_by_producer)

            # TODO: set share on edge -> new method on consumer: inject_share_to(producer)
            consumer
              .node
              .input(:useable_heat)
              .edges
              .detect { |e| e.rgt_node == producer_node_key }
              .share = consumer_share_met_by_producer
          end
        end
      end

      # Internal: The adapters which map nodes from the graph to activities
      # within Fever.
      def adapters
        @adapters ||= []
      end

      private

      def adapter_for(node_key)
        adapter = Adapter.adapter_for(
          @context.graph.node(node_key), @context
        )
        adapters << adapter

        adapter
      end
    end
  end
end
