# frozen_string_literal: true

class Benchmarks

  class Runner

    class Base
      REPORT_BASE_PATH = 'tmp/benchmarks'.freeze

      attr_reader :result, :benchmark_time

      def initialize(profiler:, output_path:)
        @profiler = profiler
        @output_path = output_path
        @filename = nil
        @benchmark_time = nil
        @result = nil
      end

      def run; end # Descendants: please implement!

      def run_benchmark(user_values: {}, gqueries: nil)
        # Set the general input keys as gqueries.
        benchmark_gqueries = gqueries || Benchmarks::Utils::Scenario.general_input_keys

        start_time = Time.zone.now

        @result = @profiler.profile(filename: @filename, output_path: @output_path) do
          Benchmarks::Utils::Scenario.update_scenario(@scenario, user_values, benchmark_gqueries)
        end

        @benchmark_time = Time.zone.now - start_time

        @result
      end

      private

      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end
