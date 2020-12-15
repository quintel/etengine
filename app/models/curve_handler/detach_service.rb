# frozen_string_literal: true

module CurveHandler
  # Removes an attachment, unsetting any inputs which the may be been set when the attachmetn was
  # originally added.
  class DetachService
    # Public: Calls the DetachService, removing the attachment. Looks up the config based on the
    # attachment type.
    def self.call(attachment)
      # rubocop:disable Rails/DynamicFindBy
      new(Config.find_by_db_key(attachment.key, allow_nil: true)).call(attachment)
      # rubocop:enable Rails/DynamicFindBy
    end

    def initialize(config)
      @config = config
    end

    def call(attachment)
      scenario = attachment.scenario
      attachment.destroy

      if @config&.sets_inputs?
        @config.input_keys.each do |key|
          scenario.user_values.delete(key)
        end

        scenario.save(validate: false)
      end

      true
    end
  end
end
