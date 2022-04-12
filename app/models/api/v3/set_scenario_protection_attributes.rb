# frozen_string_literal: true

module Api
  module V3
    # Sets the scenario `api_read_only`` and `keep_compatible`` attributes based on the params sent
    # by an API request. Maintains backwards compatibility with the old `protected` attribute.
    class SetScenarioProtectionAttributes
      def self.call(params:, scenario:)
        new(params).call(scenario)
      end

      def initialize(params)
        @params = params
      end

      def call(scenario)
        if @params.key?(:read_only) || @params.key?(:protected)
          scenario.api_read_only = scenario.keep_compatible =
            to_bool(@params.fetch(:read_only, @params[:protected]))
        elsif @params.key?(:keep_compatible)
          scenario.keep_compatible = to_bool(@params[:keep_compatible])
        end
      end

      private

      # Internal: Converts a boolean-like value from the API to true or false.
      def to_bool(value)
        ActiveRecord::Type::Boolean.new.cast(value)
      end
    end
  end
end
