module Api
  module V3
    class ScenarioMetadataHandler
      attr_reader :metadata

      def initialize(scenario, scenario_data)
        @scenario = scenario
        @scenario_data = scenario_data
        @metadata = extract_metadata
      end

      private

      def extract_metadata
        @scenario_data.key?(:metadata) ? @scenario_data[:metadata] : @scenario.metadata.dup
      end
    end
  end
end
