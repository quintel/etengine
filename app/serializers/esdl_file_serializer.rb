# frozen_string_literal: true

# Provides JSON information about an esdl_file.
class EsdlFileSerializer
  # Creates a presenter for a ScenarioAttachment with an ActiveStorage
  # attachment.
  def initialize(attachment, download = false)
    @attachment = attachment
    @esdl_file = attachment.file
    @download = download
  end

  def as_json(*)
    return {} unless @esdl_file.attached?

    attributes = {
      filename: @esdl_file.filename,
      created_at: @esdl_file.created_at
    }
    attributes = attributes.merge({ file: @esdl_file.download }) if @download

    attributes
  end
end
