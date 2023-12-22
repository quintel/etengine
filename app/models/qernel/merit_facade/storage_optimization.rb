# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Generates a residual load curve (the sum of all demands minus always-on supply) and allows one
    # or more batteries to be used to flatten the curve as much as possible.
    class StorageOptimization
      EMPTY_CURVE = Merit::Curve.new([0.0] * 8760).freeze
      PRODUCTION_TYPES = %i[must_run volatile].freeze

      # Public: Converts the amount of energy stored in a reserve to hour charging (negative) and
      # discharging (positive) loads.
      def self.reserve_to_load(reserve, output_efficiency: 1.0)
        reserve.map.with_index do |value, index|
          value = reserve[index - 1] - value
          value.positive? ? value * output_efficiency : value
        end
      end

      # Public: Creates a new Optimization which receives all of the adapters from the Merit plugin.
      def initialize(adapters, order = [], optimizing_type: :optimizing_storage)
        @adapters = adapters
        @order = order.map(&:to_s)
        @optimizing_type = optimizing_type
      end

      # Public: Returns an array describing how much energy will be stored in the named battery in
      # each hour.
      def reserve_for(key)
        reserves.fetch(key)
      end

      # Public: Returns the hourly load of the named battery. Negative loads indicate charging while
      # negative loads are charging.
      def load_for(key)
        self.class.reserve_to_load(
          reserve_for(key),
          output_efficiency: battery(key).optimizing_storage_params.output_efficiency
        )
      end

      def residual_load
        Merit::CurveTools.add_curves([consumption_curve, production_curve])
      end

      # Public: Returns wether the given battery is being optimized
      def optimizing?(key)
        reserves.key?(key)
      end

      private

      def reserves
        return @reserves unless @reserves.nil?

        @reserves = {}
        res_load = residual_load.to_a

        allowed_input  = [Float::INFINITY] * 8760
        allowed_output = [Float::INFINITY] * 8760

        last_battery = batteries.last

        batteries.each do |battery|
          key = battery.node.key

          @reserves[key] = run_algorithm(
            battery.optimizing_storage_params,
            res_load,
            allowed_input,
            allowed_output
          )

          break if battery == last_battery

          res_load = add_curves(
            res_load,
            self.class.reserve_to_load(@reserves[key]).map(&:-@)
          )

          # Update the allowed input and output to prevent subsequent batteries from charging when
          # a previous battery discharged, and vice-versa.
          self.class.reserve_to_load(@reserves[key]).each_with_index do |value, index|
            if value.positive?
              # Battery is discharging. Future batteries may not charge here.
              allowed_input[index] = 0
            elsif value.negative?
              # Battery is charging. Future batteries may not discharge here.
              allowed_output[index] = 0
            end
          end
        end

        @reserves
      end

      # Internal: Runs the optimization algorithm, returning the amount of energy stored in the
      # reserve in each hour.
      def run_algorithm(params, residual_load, allowed_input, allowed_output)
        if params.installed?
          Merit::Flex::OptimizingStorage.run(
            residual_load,
            input_capacity: params.input_capacity,
            output_capacity: params.output_capacity,
            charging_limit: allowed_input,
            discharging_limit: allowed_output,
            volume: params.volume,
            output_efficiency: params.output_efficiency,
          ).to_a
        else
          Array.new(8760, 0.0)
        end
      end

      # Internal: Retrieves an optimizing storage adapter by its node key.
      def battery(key)
        batteries.find { |b| b.node.key == key } || raise("No such optimizing storage: #{key}")
      end

      # Internal: Returns all optimizing storage adapters.
      def batteries
        @batteries ||= begin
          optimizing = @adapters.select do |adapter|
            adapter.config.subtype == @optimizing_type && adapter.config.type == :flex
          end

          optimizing.sort_by.with_index do |adapter, index|
            [@order.index(adapter.node.key.to_s) || Float::INFINITY, index]
          end
        end
      end

      # Internal: Returns a Merit::Curve describing the sum of production for each hour.
      def production_curve
        production = @adapters
          .select { |a| a.config.type == :producer && PRODUCTION_TYPES.include?(a.config.subtype) }
          .map { |c| c.participant.load_curve }

        (Merit::CurveTools.add_curves(production) || EMPTY_CURVE).map(&:-@)
      end

      # Internal: Returns a Merit::Curve describing the sum of consumption for each hour.
      def consumption_curve
        consumption = @adapters
          .select { |a| a.config.type == :consumer && a.config.subtype != :pseudo }
          .map { |c| c.participant.load_curve }

        Merit::CurveTools.add_curves(consumption) || EMPTY_CURVE
      end

      def add_curves(one, two)
        Array.new(one.length) { |index| one[index] + two[index] }
      end
    end
  end
end
