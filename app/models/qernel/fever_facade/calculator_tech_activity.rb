# frozen_string_literal: true

module Qernel
  module Fever
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
        # TODO: do we have to memo this? Yes, because we have to trace the actiities agian
        # Is that not possibe throught he calculator
        @activities ||= producers.map do |producer, share|
          producer.participant(share / total_share)
        end
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
