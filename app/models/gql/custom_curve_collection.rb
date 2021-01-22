# frozen_string_literal: true

module Gql
  # A wrapper around a hash, containing all custom curves which have been attached to the scenario.
  # Curves for which no config exists are not included.
  class CustomCurveCollection
    delegate :fetch, :key?, :keys, :length, to: :@curves

    # Public: Creates a CustomCurveCollection from the attachments on a scenario.
    def self.from_scenario(scenario)
      curve_attachments = scenario.attachments.select(&:loadable_curve?)

      new(
        curve_attachments.each_with_object({}) do |attachment, state|
          config = CurveHandler::Config.find_by(db_key: attachment.key)

          state[config.key] = Merit::Curve.reader.read(
            ActiveStorage::Blob.service.path_for(attachment.file.key)
          ).freeze
        end
      )
    end

    def initialize(curves)
      @curves = curves
    end
  end
end
