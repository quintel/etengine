# frozen_string_literal: true

# Usage:
#   updater = ScenarioUpdater.new(scenario, params, current_user)
#   if updater.apply
#     # scenario updated successfully
#   else
#     # check updater.errors
#   end
class ScenarioUpdater
  include ActiveModel::Validations

  attr_reader :scenario, :errors

    def initialize(scenario, params, current_user)
      @scenario = scenario
      @params = params
      @current_user = current_user
      @errors = ActiveModel::Errors.new(self)

      initialize_components
    end

    def apply
      return true if @params.empty?

      # Couplings
      @couplings_manager.apply_active_couplings_list! #Inspect controller
      @couplings_manager.activate_from_provided_values( # API
        @inputs_update.provided_values_without_resets
      )

      # Inputs - calculate and validate
      @inputs_update.process

      # Validate
      return false unless valid?

      # Merge attributes
      @scenario.attributes = @scenario.attributes.except(
        'id', 'present_updated_at', 'created_at', 'updated_at'
      ).merge(
        attributes_to_apply.merge(
          user_values: @inputs_update.user_values,
          balanced_values: @inputs_update.balanced_values
        )
      )

      return false unless @scenario.save(validate: false)

      # Post Save
      copy_preset_roles_if_requested
      @scenario.scenario_version_tag&.update(user: @current_user)

      true
    end

    def valid?
      components = [@inputs_update, @scenario]

      all_valid = components.all?(&:valid?)

      # Aggregate errors from components
      @inputs_update.errors.each do |error|
        errors.add(error.attribute, error.message)
      end

      # Add scenario errors
      unless @scenario.valid?
        @scenario.errors.each do |error|
          errors.add(:base, "Scenario #{error.attribute} #{error.message}")
        end
      end

      all_valid
    rescue RuntimeError => e
      errors.add(:base, e.message)
      false
    end

    private

    def initialize_components
      @couplings_manager = Inputs::CouplingsManager.new(@scenario, @params, @current_user)
      @inputs_update = Inputs::Update.new(@scenario, @params, @current_user, couplings_manager: @couplings_manager)
    end

    # Filters and prepares scenario attributes for update
    def attributes_to_apply
      scenario_data = (@params[:scenario] || {}).with_indifferent_access

      scenario_data
        .except(:area_code, :end_year, :set_preset_roles, :user_values)
        .merge(metadata: metadata_to_apply)
    end

    # Returns metadata to apply - either from params or duplicates existing
    def metadata_to_apply
      scenario_data = (@params[:scenario] || {}).with_indifferent_access

      if scenario_data.key?(:metadata)
        scenario_data[:metadata]
      else
        @scenario.metadata.dup
      end
    end

    # Copies preset roles to scenario if requested via params
    def copy_preset_roles_if_requested
      truthy_values = [true, 'true', '1']
      scenario_params = @params.dig(:scenario) || {}
      should_copy = truthy_values.include?(scenario_params.fetch(:set_preset_roles, false))

      @scenario.copy_preset_roles if should_copy
    end
end
