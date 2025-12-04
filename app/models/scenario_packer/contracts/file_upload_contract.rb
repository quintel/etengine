# frozen_string_literal: true

module ScenarioPacker
  module Contracts
    # Contract for validating file upload parameters
    class FileUploadContract < Dry::Validation::Contract
      params do
        required(:file).value(:any)
        optional(:extension).filled(:string)
      end

      rule(:file) do
        next key.failure('must be an uploaded file with a path') unless value.respond_to?(:path)
        next key.failure('file does not exist') unless File.exist?(value.path)
      end

      rule(:file, :extension) do
        next unless values[:extension]
        next unless values[:file].respond_to?(:path)

        path = values[:file].path
        key.failure("must be a #{values[:extension]} file") unless path.end_with?(values[:extension])
      end
    end
  end
end
