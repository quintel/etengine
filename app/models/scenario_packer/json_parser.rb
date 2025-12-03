# frozen_string_literal: true

module ScenarioPacker
  # Utility module for JSON parsing with consistent error handling
  module JsonParser
    extend Dry::Monads[:result]

    def self.parse(json_string)
      Success(JSON.parse(json_string))
    rescue JSON::ParserError => e
      Failure("Failed to parse JSON: #{e.message}")
    end

    def self.parse_ndjson(content)
      lines = content.lines.map(&:strip).reject(&:empty?)
      results = []
      errors = []

      lines.each_with_index do |line, index|
        JSON.parse(line).then { |data| results << data }
      rescue JSON::ParserError => e
        errors << "Line #{index + 1}: Failed to parse JSON - #{e.message}"
      end

      if errors.any?
        Failure(errors)
      else
        Success(results)
      end
    end
  end
end
