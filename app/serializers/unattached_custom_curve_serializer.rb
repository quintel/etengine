# frozen_string_literal: true

# Provides JSON information about a custom curve.
class UnattachedCustomCurveSerializer
  # Renders information about a file which can be attached to a scenario, but which currently has no
  # attachment.
  #
  # config - A CurveHandler::Config.
  def initialize(config)
    @config = config
  end

  def as_json(*)
    data = {
      key: @config.key,
      type: @config.processor_key,
      display_group: @config.display_group,
      attached: false,
      overrides: @config.public_disabled_inputs
    }

    data[:internal] = true if @config.internal?

    data
  end
end
