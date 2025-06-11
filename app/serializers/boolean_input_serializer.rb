class BooleanInputSerializer < InputSerializer
  def as_json(*)
    json   = super

    values = Input.cache(@scenario.original).read(@scenario.original, @input)
    default_val = @default_values_from.call(values)
    user_val    = @scenario.user_values[@input.key] || @scenario.balanced_values[@input.key]

    json[:min]     = false
    json[:max]     = true
    json[:default] = default_val == 1.0
    json[:unit]    = 'bool'

    json
  end
end
