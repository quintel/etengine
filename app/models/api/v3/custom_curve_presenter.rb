# frozen_string_literal: true

module Api
  module V3
    # Provides JSON information about a custom curve.
    class CustomCurvePresenter
      # Creates a presenter using an ActiveStorage attachment.
      def initialize(attachment)
        @attachment = attachment
      end

      def as_json(*)
        return {} unless @attachment.attached?

        {
          type: @attachment.name.to_s.chomp('_curve'),
          name: @attachment.filename.to_s,
          size: @attachment.byte_size,
          date: @attachment.created_at.utc,
          stats: stats
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
            ActiveStorage::Blob.service.path_for(@attachment.key)
          ).to_a
      end
    end
  end
end
