# frozen_string_literal: true

module ScenarioUpdater
  class PresetHandler < Base
    TRUTHY_VALUES = Set.new([true, 'true', '1']).freeze

    def should_copy_preset_roles?
      scenario_params = params.dig(:scenario) || {}
      TRUTHY_VALUES.include?(scenario_params.fetch(:set_preset_roles, false))
    end

    def copy_roles
      return unless should_copy_preset_roles?
      scenario.copy_preset_roles
    end
  end
end
