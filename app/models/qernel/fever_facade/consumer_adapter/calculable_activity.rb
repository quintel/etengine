# frozen_string_literal: true

module Qernel
  module FeverFacade
    class ConsumerAdapter < Adapter
      # Helps with setting up calculators for different tech activities
      # We make them part of consumers, because in the end the consumer has
      # to which tech activities are participating to mix back its curves!
      module CalculableActivity
        EMPTY_CURVE = Merit::Curve.new([0.0] * 8760).freeze

        # TODO: do we setup like this and check for empty, or dynamically add keys when we need them?
        def calculable_activities
          @calculable_activities ||= tech_curves.keys.inject({}) do |tech_activities, tech_type|
            tech_activities[tech_type] = CalculatorTechActivity.new
            tech_activities
          end
        end

        def finish_setup!
          @calculable_activities.each do |tech_type, activity|
            next if activity.empty?

            activity.consumer_participant = participant_for(tech_type, activity.total_share)
          end
        end

        def participant_for(tech_type, share)
          Fever::Consumer.new(demand_curve(tech_type, share).to_a)
        end

        def build_activity(producer, share)
          calculable_activities[producer.tech_type].add(producer, share)
        end

        # After calculations have run for each tech component of the consumer,
        # the curves are summed back together
        def demand_curve_from_activities
          # TODO: this is not so nice -> maybe do like the top todo, because now we need a filter map
          # what if they are all empty? do we get an error or will Merit gently give us an empty curve?
          Merit::CurveTools.add_curves(
            calculable_activities.filter_map do |activity|
              activity.consumer_participant.demand_curve unless activity.empty?
            end
          ) || EMPTY_CURVE
        end
      end
    end
  end
end
