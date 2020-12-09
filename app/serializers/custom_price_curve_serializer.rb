# frozen_string_literal: true

# Provides JSON information about a custom price curve.
class CustomPriceCurveSerializer < CustomCurveSerializer
  def as_json(*)
    attrs = super
    attrs[:source_scenario] = @attachment.metadata_json unless attrs.empty?

    attrs
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
end
