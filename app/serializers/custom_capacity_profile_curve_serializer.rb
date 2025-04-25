# frozen_string_literal: true

class CustomCapacityProfileCurveSerializer < CustomCurveSerializer
  private

  def stats
    attrs = super

    if config.sets_inputs?
      flh = Scenario.find(@user_curve.scenario_id).user_values[config.input_keys.first]
      attrs[:full_load_hours] = flh
    end

    attrs
  end
end
