# frozen_string_literal: true

class CustomProfileCurveSerializer < CustomCurveSerializer
  private

  def stats
    attrs = super

    if config.reducer
      reduced = config.reducer.call(@curve.to_a)
      attrs[:full_load_hours] = reduced
    end

    attrs
  end
end
