module Api
  module V3
    # Given a scenario, and parameters from an HTTP request, updates the
    # scenario with the data, or presents a useful error to sent back to the
    # client.
    class ScenarioUpdater
      include ActiveModel::Validations

      validate :validate_scenario

      attr_reader :scenario, :errors

      def initialize(scenario, params, current_user)
        @scenario = scenario
        @current_user = current_user
        @data = (params.to_h || {}).with_indifferent_access
        @scenario_data = (@data[:scenario] || {}).with_indifferent_access

        @metadata_handler = ScenarioMetadataHandler.new(@scenario, @scenario_data)
        @input_processor = ScenarioInputProcessor.new(@scenario_data, @scenario, @data, current_user)
        @validator = ScenarioValidator.new(
          @scenario,
          @data,
          @input_processor.provided_values,
          @input_processor.provided_values_without_resets,
          @input_processor.user_values,
          @input_processor.balanced_values,
          method(:each_group),
          @current_user
        )
        @errors = ActiveModel::Errors.new(self)
      end

      # Applies the user changes to the scenario and saves it to the database.
      # @return [Boolean]
      def apply
        return true if @data.empty?

        @scenario.attributes = @scenario.attributes.except(
          'id', 'present_updated_at', 'created_at', 'updated_at'
        ).merge(
          @scenario_data
            .except(:area_code, :end_year, :set_preset_roles)
            .merge(
              balanced_values: @input_processor.balanced_values,
              user_values: @input_processor.user_values,
              metadata: @metadata_handler.metadata
            )
        )

        if valid? && @scenario.valid?
          return false unless @scenario.save(validate: false)

          @scenario.copy_preset_roles if copy_preset_roles?
          @scenario.scenario_version_tag&.update(user: @current_user)
          true
        else
          merge_errors
          false
        end
      end

      private

      # Validates the scenario and merges any validation errors.
      def validate_scenario
        @validator.validate
        @validator.errors.each do |error|
          errors.add(:base, error.message)
        end

        unless @scenario.valid?
          @scenario.errors.each do |error|
            errors.add(:base, "Scenario #{error.attribute} #{error.message}")
          end
        end
      end

      # Merges errors from the validator into the updater's errors.
      def merge_errors
        @validator.errors.each do |error|
          errors.add(:base, error.message)
        end
      end

      # Determines if preset roles should be copied.
      # @return [Boolean]
      def copy_preset_roles?
        ScenarioValidator::TRUTHY_VALUES.include?(@scenario_data.fetch(:set_preset_roles, false))
      end

      # Iterates over each group of inputs in the scenario.
      def each_group(values, &block)
        ScenarioValidator.each_group(@scenario, values, &block)
      end
    end
  end
end
