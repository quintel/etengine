# frozen_string_literal: true

class Benchmarks

  class Runner

    class Input < Benchmarks::Runner::Base
      INPUT_PATH = "#{REPORT_BASE_PATH}/inputs".freeze
      INDIVIDUAL_INPUT_PATH = "#{INPUT_PATH}/individual".freeze
      COMBINED_INPUT_PATH = "#{INPUT_PATH}/combined".freeze

      def initialize(profiler:, inputs: nil, output_path: nil)
        super(profiler:, output_path:)

        @inputs = inputs
      end

      def run(type:)
        case type
        when '-i', '--individually'
          logger.info('Commencing benchmarks for all individual inputs:')

          @inputs = InputUtils.inputs_per_slide

          run_individual
        when '-is', '--individually-short'
          logger.info('Commencing benchmarks for one random input from all slides:')

          @inputs = InputUtils.inputs_per_slide(max_inputs_per_slide: 1)

          run_individual
        when '-c', '--combined'
          logger.info('Commencing benchmarks for inputs of different combinations:')

          [5, 10, 20, 50].each do |quantity|
            run_with_quantity_and_keyword(quantity:)
          end
        when '-cs', '--combined-per-sector'
          logger.info('Commencing benchmarks for inputs of different combinations per sector:')

          [5, 10, 20, 50].each do |quantity|
            # Test these quantities for all major sectors. Match inputs that have keys containing:
            #   'agriculture' and 'agricultural',
            #   'household' and 'households',
            #   'industry' and 'industrial'
            %w[agricultur household industr].each do |keyword|
              run_with_quantity_and_keyword(quantity:, keyword:)
            end
          end
        end
      end

      ## Quantity and/or sector benchmark
      #
      # Test the effects of setting multiple slide inputs in one request.
      # When a keyword is given only inputs matching the keyword are included.
      # When a quantity is given random input slides are picked.
      def run_with_quantity_and_keyword(quantity: 1, keyword: '')
        # Create pool with all slide keys
        slide_keys = Benchmarks::Utils::Input.all_slide_keys
        # If a keyword is given, only grab the slides containing it
        slide_keys.select { |sk| sk.includes?(keyword) } if keyword.present?

        # Randomly pick one of these slide keys and grab the input keys for it
        input_keys = Benchmarks::Utils::Input.input_keys_for_slide(slide_keys.sample)

        # Shrink the pool to the requested quantity
        input_keys = input_keys.sample(quantity)

        @inputs = {}
        input_keys.each { |key| @inputs[key] = 12 }

        input_count = @inputs.count
        @filename = \
          if keyword.present? && input_count > 1
            "#{input_count}_inputs_containing_#{keyword}.html"
          elsif keyword.present?
            "inputs_containing_#{keyword}"
          elsif @inputs.count > 1
            "#{input_count}_inputs.html"
          end

        run_combined
      end

      # In 'individual' mode we perform an individual request for each given input
      # so that we can benchmark and study their results individually.
      def run_individual
        @output_path ||= INDIVIDUAL_INPUT_PATH

        logger.info("Starting individual benchmarks for #{@inputs.count} inputs")

        @inputs.each do |input_key, gqueries|
          @filename = input_key
          run_benchmark(user_values: { "#{input_key}": 12 }, gqueries:)
        end

        logger.info("-- Done in #{@benchmark_time}s")
      end

      # In 'combined' mode we perform one request for all inputs at once
      # so we can benchmark the effects of different quantities of inputs together.
      def run_combined
        @filename ||= "#{@inputs.count}_inputs"
        @output_path ||= COMBINED_INPUT_PATH

        logger.info("Starting one combined benchmark for #{@inputs.count} inputs")

        run_benchmark(user_values: @inputs)

        logger.info("-- Done in #{@benchmark_time}s")
      end
    end
  end
end
