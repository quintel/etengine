# frozen_string_literal: true

module ScenarioUpdater
  class Orchestrator
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

      # 1. Activate couplings first
      @couplings_manager.activate_from_provided_values(
        @inputs_update.provided_values_without_resets
      )

      # 2. Process inputs (calculate + validate)
      @inputs_update.process

      # 3. Validate everything
      return false unless valid?

      # 4. Merge all attributes
      @scenario.attributes = @scenario.attributes.except(
        'id', 'present_updated_at', 'created_at', 'updated_at'
      ).merge(
        @attributes.attributes_to_apply.merge(
          user_values: @inputs_update.user_values,
          balanced_values: @inputs_update.balanced_values
        )
      )

      # 5. Save
      return false unless @scenario.save(validate: false)

      # 6. Post-save actions
      @preset_handler.copy_roles
      @scenario.scenario_version_tag&.update(user: @current_user)

      true
    end

    def valid?
      components = [@attributes, @inputs_update, @scenario]

      all_valid = components.all? do |component|
        component == @scenario ? component.valid? : component.valid?
      end

      # Aggregate errors from components
      @attributes.errors.each do |error|
        errors.add(error.attribute, error.message)
      end

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
      @attributes = Attributes.new(@scenario, @params, @current_user)
      @preset_handler = PresetHandler.new(@scenario, @params, @current_user)
      @inputs_update = Inputs::Update.new(@scenario, @params, @current_user)
      @couplings_manager = Inputs::CouplingsManager.new(@scenario, @params, @current_user)
    end
  end
end
