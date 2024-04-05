# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Sets up and represents a Fever::Calculator for the tech variant of a consumer
    class CalculatorTechActivity
      attr_accessor :consumer_participant

      # Public: Instructs the calculator to compute a single frame.
      #
      # frame - The frame number to be calculated.
      #
      # Returns nothing.
      delegate :calculate_frame, to: :calculator

      # Public: The Fever::Calculator containing the tech participant for the consumer and
      # the activities with correctly setup shares
      def calculator
        # Unless there are no activities/producers! or no participant
        @calculator ||= Fever::Calculator.new(consumer_participant, activities)
      end

      def empty?
        producers.none?
      end

      def activities
        @activities ||= producers.map do |producer, share|
          producer.participant(share / total_share)
        end
      end

      def activity(producer)
        producer_keys = producers.map { |p, _| p.node.key }
        return unless producer_keys.include?(producer.node.key)

        activities[producer_keys.index(producer.node.key)]
      end

      def producers
        @producers ||= []
      end

      def add(producer, share)
        producers << [producer, share]
      end

      def total_share
        @total_share ||= producers.sum { |_, share| share }
      end
    end
  end
end
