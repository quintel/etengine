# frozen_string_literal: true

class Benchmarks

  class Runner

    class Scenario < Benchmarks::Runner::Base
      SCENARIO_PATH = "#{REPORT_BASE_PATH}/scenarios".freeze

      def initialize(profiler:, scenario_ids:, output_path: nil)
        super(profiler:, output_path:)

        @scenario_ids = scenario_ids
        @scenarios = []
        @output_path ||= SCENARIO_PATH

        validate_scenario_ids

        load_scenarios
      end

      def run
        @scenarios.each do |scenario|
          gqueries = ['dashboard_total_costs']

          logger.info("Starting benchmark for scenario #{scenario.id}...")

          @scenario = Benchmarks::Utils::Scenario.clone_scenario(scenario)
          @filename = "scenario_#{scenario.id}"
          run_benchmark(user_values: {}, gqueries:)

          @scenario.destroy

          logger.info("-- Profiling done in #{@benchmark_time}")
        end
      end

      private

      def validate_scenario_ids
        begin
          @scenario_ids = @scenario_ids.split(',').map(&:to_i)
        rescue e
          raise 'Expected one or more scenario ids!'
        end

        raise 'Expected one or more scenario ids!' unless @scenario_ids.all?(Numeric)
      end

      def load_scenarios
        @scenarios = ::Scenario.where(id: @scenario_ids)
      end
    end
  end
end
