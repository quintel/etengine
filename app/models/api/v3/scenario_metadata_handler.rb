# frozen_string_literal: true

module Api
  module V3
    class ScenarioMetadataHandler

      def initialize(scenario, scenario_data)
        @scenario = scenario
        @scenario_data = scenario_data
      end

      def metadata
        @scenario_data.key?(:metadata) ? @scenario_data[:metadata] : @scenario.metadata.dup
      end

      def validate_metadata_size(errors)
        errors.add(:base, 'Metadata can not exceed 64Kb') if metadata.to_s.bytesize > 64.kilobytes
      end
    end
  end
end
