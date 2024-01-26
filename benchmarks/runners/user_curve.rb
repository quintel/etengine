# frozen_string_literal: true

class Benchmarks

  ###
  # Benchmarks to measure the effects of setting and loading scenarios with custom (user) curves
  #
  class Runner::Curve < Runner::Base
    extend Benchmarks

    REPORT_PATH = "#{Benchmarks::REPORT_BASE_PATH}/user_curves".freeze

    class << self
      def run(quantity)
        run_warmup_benchmark

        curve_quantities = \
          if quantity.is_a?(String) && quantity.include?(',')
            quantity.split(',').map(&:to_i)
          else
            [quantity.to_i]
          end

        inputs = Benchmarks::Utils::Input.one_input_per_slide

        curve_quantities.each do |curve_quantity|
          scenario = Benchmarks::Utils::Scenario.create_scenario

          (1..curve_quantity).each do |i|
            Benchmarks::Utils::Curve.add_curve_to_scenario(scenario, Benchmarks::Utils::Curve.curve_names[i - 1])
          end

          logger.info("Commencing benchmarks with #{inputs.count} inputs for new scenario with #{curve_quantity} custom curve(s) attached:")
          benchmark_time = Time.zone.now

          # Run benchmarks for selection of input keys individually
          run_scenario_benchmark(inputs: inputs, mode: 'combined', benchmark_scenario: scenario, filename: "#{curve_quantity}_curves.rb", store_path: REPORT_PATH)

          logger.info("  done in #{Time.zone.now - benchmark_time}s")

          scenario.destroy
        end
      end

    end
  end
end
