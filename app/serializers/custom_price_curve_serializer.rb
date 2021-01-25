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
    attrs = super

    attrs[:max]  = curve[attrs[:max_at]]
    attrs[:min]  = curve[attrs[:min_at]]
    attrs[:mean] = curve.sum / curve.length

    attrs
  end
end
