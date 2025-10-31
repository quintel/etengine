# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Handles post-save operations like copying preset roles and updating version tags.
    class PostSaveOperations
      include Dry::Monads[:result]

      TRUTHY_VALUES = Set.new([true, 'true', '1']).freeze

      def call(scenario, set_preset_roles, current_user)
        copy_preset_roles_if_requested(scenario, set_preset_roles)
        update_version_tag(scenario, current_user)

        Success(scenario)
      end

      private

      def copy_preset_roles_if_requested(scenario, set_preset_roles)
        should_copy = TRUTHY_VALUES.include?(set_preset_roles)
        scenario.copy_preset_roles if should_copy
      end

      def update_version_tag(scenario, current_user)
        scenario.scenario_version_tag&.update(user: current_user)
      end
    end
  end
end
