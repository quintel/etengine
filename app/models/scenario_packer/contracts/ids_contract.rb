# frozen_string_literal: true

module ScenarioPacker
  module Contracts
    # Contract for validating and parsing scenario ID lists
    class IdsContract < Dry::Validation::Contract
      params do
        required(:ids).value(:any)
      end

      rule(:ids) do
        parsed = parse_ids(value)
        next key.failure('at least one valid ID required') if parsed.empty?

        values[:parsed_ids] = parsed
      end

      def parse_ids(ids)
        Array(ids.to_s)
          .flat_map { |s| s.split(/\s*,\s*/) }
          .map(&:to_i)
          .reject(&:zero?)
          .uniq
      end
    end
  end
end
