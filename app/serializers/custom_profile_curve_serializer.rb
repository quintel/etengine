# frozen_string_literal: true

# Provides JSON information about a custom price curve.
class CustomProfileCurveSerializer < CustomCurveSerializer
  private

  def stats
    attrs = super

    if config.reducer == CurveHandler::Reducers::FullLoadHours
      attrs[:full_load_hours] = CurveHandler::Reducers::FullLoadHours.call(curve)
    end

    attrs
  end
end
