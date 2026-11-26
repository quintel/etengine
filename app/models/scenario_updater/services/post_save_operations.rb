# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Handles post-save operations like copying preset roles and updating version tags.
    class PostSaveOperations
      include Dry::Monads[:result]

      TRUTHY_VALUES = Set.new([true, 'true', '1']).freeze

      def call(scenario, current_user)
        update_version_tag(scenario, current_user)

        Success(scenario)
      end

      private

      def update_version_tag(scenario, current_user)
        scenario.scenario_version_tag&.update(user: current_user)
      end
    end
  end
end
