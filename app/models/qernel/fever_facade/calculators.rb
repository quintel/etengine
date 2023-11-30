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
        setup
      end

      # A list of CalculatorTechActivities
      def calculators
        @calculators ||= ordered_consumer_adapters.flat_map do |consumer|
          consumer.finish_setup!
          consumer.calculable_activities.values
        end
      end

      def calculate_frame(frame)
        calculators.each { |calc| calc.calculate_frame(frame) }
      end

      # Sets up the adapters and matched consumers to create e network to intialize the calculators
      def setup
        @ordered_producers.each do |producer_node_key|
          producer = adapter_for(producer_node_key)

          producer_share = producer.share_in_group
          # verify this is correct behaviour. what happens with the share zero things in fever itsefl?
          next if producer_share.zero?

          # For each ordered consumer, check if an activity should be added to it's calculator
          ordered_consumer_adapters.each do |consumer|
            # Check if the producer is either done or did not join in the first place
            # TODO: not just next, but we can break here! if the "next" above is correct
            next if producer_share.zero?

            # Another producer already filled up the whole consumer or there are no hh in consumer
            next if consumer.share_met == 1.0 || consumer.number_of_units.zero?

            consumer_share_in_total = consumer.number_of_units / total_number_of_units

            # Now we calculate the share between this consumer and the producer.
            # The maximum share of buildings/houses the producer can supply to is:
            # The minimum of the share of houses the producers still has to deliver to,
            # and the share of houses/buldings the consumer represents, multiplied by
            # if other producers already met a piece of its demand.
            consumer_share = [
              producer_share,
              consumer_share_in_total * (1.0 - consumer.share_met)
            ].min

            # Keep track on to how many housholds/buidlings the producer still needs to deliver
            producer_share -= consumer_share

            consumer_share_met_by_producer = consumer_share / consumer_share_in_total

            # TODO: Can this be one thing?
            consumer.build_activity(producer, consumer_share_met_by_producer)
            consumer.inject_share_to_producer(producer, consumer_share_met_by_producer, producer_share)
          end
        end
      end

      # Internal: The adapters which map nodes from the graph to activities
      # within Fever.
      def adapters
        @adapters ||= []
      end

      # Always in correct order!
      # TODO: how does this one live together with the plain "adapters"?
      def ordered_consumer_adapters
        @ordered_consumer_adapters ||= @ordered_consumers.map { |node_key| adapter_for(node_key) }
      end

      def total_number_of_units
        @total_number_of_units ||= ordered_consumer_adapters.sum(&:number_of_units)
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
