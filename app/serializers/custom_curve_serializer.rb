# frozen_string_literal: true

# Provides JSON information about a custom curve.
class CustomCurveSerializer
  # Creates a presenter for a ScenarioAttachment with an ActiveStorage
  # attachment.
  def initialize(attachment)
    @attachment = attachment
    @custom_curve = attachment.file
  end

  def as_json(*)
    return {} unless @custom_curve.attached?

    {
      key: key,
      type: config.processor_key,
      display_group: config.display_group,
      overrides: config.input_keys,
      attached: true,
      name: @custom_curve.filename.to_s,
      size: @custom_curve.byte_size,
      date: @custom_curve.created_at.utc,
      stats: stats
    }
  end

  private

  def key
    @attachment.key.chomp('_curve')
  end

  def config
    CurveHandler::Config.find(key)
  end

  def stats
    { length: curve.length }
  end

  def curve
    @curve ||=
      Merit::Curve.load_file(
        ActiveStorage::Blob.service.path_for(@custom_curve.key)
      ).to_a
  end
end
