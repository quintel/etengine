# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Prepares scenario attributes by merging existing attributes
    # with updates from scenario data, user_values, and balanced_values.
    class PrepareAttributes
      include Dry::Monads[:result]

      def call(scenario, user_values, balanced_values, scenario_data)
        # Filter out attributes that shouldn't be updated
        filtered_attrs = scenario_data
          .except(:area_code, :end_year, :set_preset_roles, :user_values)
          .merge(metadata: metadata_to_apply(scenario, scenario_data))

        # Merge all attributes together
        final_attrs = scenario.attributes
          .except('id', 'present_updated_at', 'created_at', 'updated_at')
          .merge(filtered_attrs)
          .merge(
            user_values: user_values,
            balanced_values: balanced_values
          )

        Success(final_attrs)
      end

      private

      def metadata_to_apply(scenario, scenario_data)
        if scenario_data.key?(:metadata)
          scenario_data[:metadata]
        else
          scenario.metadata.dup
        end
      end
    end
  end
end
