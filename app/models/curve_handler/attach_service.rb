# frozen_string_literal: true

module CurveHandler
  # Processes and validates user-uploaded curves.
  #
  # AttachService creates/updates a UserCurve record with the serialized curve data.
  class AttachService
    delegate :error_keys, :errors, :valid?, to: :@processor

    # config   - A Config which describes the type of curve and how it should be handled.
    # file     - The uploaded file.
    # scenario - The scenario to which the curve will be attached.
    # metadata - Metadata to be stored with the curve.
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

    def call(set_inputs=true)
      return false unless @processor.valid?

      # Update name and metadata
      update_metadata

      # Build a Merit::Curve using the sanitized curve data.
      user_curve.curve = merit_curve
      user_curve.save!

      set_input_values if set_inputs

      user_curve
    end

    private

    # Returns the user curve attached to the scenario, or a new record
    def user_curve
      @user_curve ||= if @scenario.attached_curve?(@config.db_key)
        @scenario.attached_curve(@config.db_key)
      else
        UserCurve.create!(
          key: @config.db_key,
          scenario: @scenario,
          curve: merit_curve
        )
      end
    end

    def merit_curve
      Merit::Curve.new(@processor.curve_for_storage)
    end

    def update_metadata
      user_curve.name = @filename.chomp(File.extname(@filename))
      user_curve.update_or_remove_metadata(@metadata)
    end

    def set_input_values
      return unless @config.sets_inputs?

      reduced = Reducer
        .new(@config.reducer, @config.key, @scenario)
        .call(@processor.sanitized_curve)

      @config.input_keys.each do |key|
        @scenario.update_input_clamped(key, reduced)
      end

      @scenario.save(validate: false)
    end
  end
end
