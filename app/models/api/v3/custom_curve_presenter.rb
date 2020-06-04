# frozen_string_literal: true

module Api
  module V3
    # Provides JSON information about a custom curve.
    class CustomCurvePresenter
      # Creates a presenter for a ScenarioAttachment with an ActiveStorage
      # attachment.
      def initialize(attachment)
        @attachment = attachment
        @custom_curve = attachment.file
      end

      def as_json(*)
        return {} unless @custom_curve.attached?

        {
          type: @attachment.key.chomp('_curve'),
          name: @custom_curve.filename.to_s,
          size: @custom_curve.byte_size,
          date: @custom_curve.created_at.utc,
          stats: stats,
          source_scenario: @attachment.metadata_json
        }
      end

      private

      def stats
        # Although it seems like one iteration through the curve would be
        # better, wherein we would determine the min, max, and sum (for the
        # mean), in fact this is not the case when benchmarked.
        min = curve.min
        max = curve.max

        {
          length: curve.length,
          mean: curve.sum / curve.length,
          min: min,
          min_at: curve.index(min),
          max: max,
          max_at: curve.index(max)
        }
      end

      def curve
        @curve ||=
          Merit::Curve.load_file(
            ActiveStorage::Blob.service.path_for(@custom_curve.key)
          ).to_a
      end
    end
  end
end
