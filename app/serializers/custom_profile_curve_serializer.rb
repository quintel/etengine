# frozen_string_literal: true

# Provides JSON information about a custom price curve.
class CustomProfileCurveSerializer < CustomCurveSerializer
  private

  def stats
    super.merge(
      full_load_hours: CurveHandler::Reducers::FullLoadHours.call(curve)
    )
  end
end
