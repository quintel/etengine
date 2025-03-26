# frozen_string_literal: true

module Gql
  # A wrapper around a hash, containing all custom curves which have been attached to the scenario.
  # Curves for which no config exists are not included.
  class CustomCurveCollection
    delegate :fetch, :key?, :keys, :length, to: :@curves

    # Public: Creates a CustomCurveCollection from the attachments on a scenario.
    def self.from_scenario(scenario)
      scenario_user_curves = scenario.user_curves.select(&:loadable_curve?)

      new(
        scenario_user_curves.each_with_object({}) do |user_curve, state|
          config = CurveHandler::Config.find_by(db_key: user_curve.key)

          next unless config

          state[config.key] = user_curve.curve.to_a.freeze
        end
      )
    end

    def initialize(curves)
      @curves = curves
    end
  end
end
