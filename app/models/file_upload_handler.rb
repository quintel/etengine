# frozen_string_literal: true

# Handles the upload of files that aren't curves, or don't need any (pre)processing like esdl files
class FileUploadHandler
  attr_reader :errors

  # Public: creates a new handler
  #
  # file     - A String version of the file that should be attached
  # filename - The name of the file
  # key      - The key of the ScenarioAttachment, e.g. 'esdl_file'
  # scenario - The scenario the file should be attached to
  def initialize(file, key, scenario)
    @file = file
    @key = key
    @scenario = scenario
  end

  # Public: attaches the file to the scenario as content type xml
  def call
    attachment = update_or_create_attachment

    attachment.file.attach(
      io: @file,
      filename: @file.original_filename,
      content_type: 'text/xml'
    )
  end

  def valid?
    @errors = []

    unless ScenarioAttachment.valid_non_curve_keys.include?(@key)
      @errors.push("This handler cannot attach files of type #{@key}.")
    end

    if @key == 'esdl_file'
      header = File.open(@file.path) { |file| file.gets(nil, 1024) }
      errors.push('This file does not contain ESDL') unless header.include?('<esdl:EnergySystem')
    end

    @errors.none?
  end

  private

  def current_attachment
    return @current_attachment if defined?(@current_attachment)

    @current_attatchment = @scenario.attachments.find_by(key: @key)
  end

  def update_or_create_attachment
    current_attachment || ScenarioAttachment.create!(key: @key, scenario: @scenario)
  end
end
