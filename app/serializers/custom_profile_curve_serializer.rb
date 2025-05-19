# frozen_string_literal: true

class CustomProfileCurveSerializer < CustomCurveSerializer
  private

  def stats
    attrs = super

    attrs[:full_load_hours] = reduced if config.reducer

    attrs
  end

  # Internal: If the config has a reducer, we know it's a capacity profile
  # many of them have already been normalized at this point, so we
  # have to check the flh input they set
  #
  # Returns the full load hours associated to the profile
  def reduced
    if config.sets_inputs? && @user_curve.scenario.user_values.key?(config.input_keys.last)
      @user_curve.scenario.user_values[config.input_keys.last]
    else
      config.reducer.call(@curve.to_a)
    end
  end
end
