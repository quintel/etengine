# frozen_string_literal: true

# Provides JSON information about a custom curve.
class UnattachedCustomCurveSerializer
  # Renders information about a file which can be attached to a scenario, but which currently has no
  # attachment.
  def initialize(key)
    @key = key
  end

  def as_json(*)
    config = CurveHandler::Config.find(@key)

    {
      key: @key,
      type: config.processor_key,
      display_group: config.display_group,
      attached: false,
      overrides: config.input_keys
    }
  end
end
