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
          @calculable_activities ||= technology_curve_types.inject({}) do |activities, tech_type|
            activities[tech_type] = CalculatorTechActivity.new
            activities
          end
        end

        def finish_setup!
          calculable_activities.each do |tech_type, activity|
            # next if activity.empty?

            activity.consumer_participant = participant_for(tech_type, activity.total_share)
          end
        end

        def build_activity(producer, share)
          @share_met += share

          calculable_activities[producer.technology_curve_type].add(producer, share)
        end

        # After calculations have run for each tech component of the consumer,
        # the curves are summed back together
        def demand_curve_from_activities
          # TODO: this is not so nice -> maybe do like the top todo, because now we need a filter map
          Merit::CurveTools.add_curves(
            calculable_activities.filter_map do |activity|
              activity.consumer_participant.demand_curve unless activity.empty?
            end
          ) || EMPTY_CURVE
        end

        def coupled_activity_for(producer)
          calculable_activities[producer.technology_curve_type]&.activity(producer)
        end

        def deficit_for(producer)
          activity = coupled_activity_for(producer)
          return unless activity

          production = activity.producer.output_curve.sum
          demand = activity.demand

          demand - production
        end

        # TODO: this is sthe total output curve! Save the one on Activity to get only the one for
        # the consumer! (IS THAT POSSIBLE????)
        def production_curve_for(producer)
          coupled_activity_for(producer)&.producer&.output_curve || EMPTY_CURVE
        end
      end
    end
  end
end
