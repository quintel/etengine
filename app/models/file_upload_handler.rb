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
    attachment = ScenarioAttachment.create!(key: @key, scenario: @scenario)

    attachment.file.attach(
      io: @file,
      filename: @file.original_filename,
      content_type: 'text/xml'
    )
  end

  def valid?
    @errors = []

    if @scenario.attachments.find_by(key: @key)
      @errors.push("This scenario already has a file of type #{@key} attached.")
      return false
    end

    unless ScenarioAttachment.valid_non_curve_keys.include?(@key)
      @errors.push("This handler cannot attach files of type #{@key}.")
    end

    if @key == 'esdl_file'
      header = File.open(@file.path) { |file| file.gets(nil, 1024) }
      errors.push('This file does not contain ESDL') unless header.include?('<esdl:EnergySystem')
    end

    @errors.none?
  end
end
