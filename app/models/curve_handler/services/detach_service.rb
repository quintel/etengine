# frozen_string_literal: true

module CurveHandler
  module Services
    # Removes a UserCurve record, unsetting any inputs that may have been set when the curve was added.
    class DetachService
      # Looks up the configuration by db_key and detaches the user curve.
      def self.call(user_curve)
        new(Config.find_by(db_key: user_curve.key, allow_nil: true)).call(user_curve)
      end

      def initialize(config)
        @config = config
      end

      def call(user_curve)
        scenario = user_curve.scenario

        user_curve.destroy

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
end
