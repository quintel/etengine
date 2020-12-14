# frozen_string_literal: true

module CurveHandler
  # Processes and validates user-uploaded curves.
  #
  # AttachService will assert that the uploaded curve is valid (deferring to the processor), saves
  # the file and ScenarioAttachment, and sets any scenario input values.
  class AttachService
    delegate :error_keys, :errors, :valid?, to: :@processor

    # Public: Creates a new Wrapper.
    #
    # config   - A Config which describes the type of curve and how it should be handled.
    # file     - The name of the uploaded file.
    # scenario - The scenario to which the curve will be attached.
    # metadata - Metadata to be stored with the curve.
    #
    def initialize(config, file, scenario, metadata = {})
      io = file.tempfile
      io.rewind

      @config = config
      @filename = file.original_filename
      @processor = config.processor.from_string(io.read)
      @scenario = scenario
      @metadata = metadata
    ensure
      io.rewind
    end

    def call
      return false unless @processor.valid?

      # Store the curve.
      attachment = update_or_create_attachment

      attachment.file.attach(
        io: StringIO.new(@processor.sanitized_curve.join("\n")),
        filename: @filename,
        content_type: 'text/csv'
      )

      set_input_values
      attachment
    end

    private

    def current_attachment
      return @current_attachment if defined?(@current_attachment)

      @current_attatchment = @scenario.attachments.find_by(key: @config.db_key)
    end

    def update_or_create_attachment
      attachment = current_attachment ||
        ScenarioAttachment.create!(key: @config.db_key, scenario_id: @scenario.id)

      # If new metadata is not supplied, remove the old data.
      attachment.update_or_remove_metadata(@metadata)
      attachment
    end

    def set_input_values
      return unless @config.sets_inputs?

      reduced = @config.reducer.call(@processor)

      @config.input_keys.each do |key|
        @scenario.user_values[key] = reduced
      end

      @scenario.save(validate: false)
    end
  end
end
