# frozen_string_literal: true

module ScenarioUpdater
  class Attributes < Base
    def attributes_to_apply
      scenario_data = (params[:scenario] || {}).with_indifferent_access

      scenario_data
        .except(:area_code, :end_year, :set_preset_roles, :user_values)
        .merge(metadata: metadata)
    end

    private

    def metadata
      scenario_data = (params[:scenario] || {}).with_indifferent_access

      if scenario_data.key?(:metadata)
        scenario_data[:metadata]
      else
        scenario.metadata.dup
      end
    end
  end
end
