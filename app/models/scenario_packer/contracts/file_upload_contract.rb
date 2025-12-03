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
        unless value.respond_to?(:path)
          key.failure('must be an uploaded file with a path')
        else
          unless File.exist?(value.path)
            key.failure('file does not exist')
          end
        end
      end

      rule(:file, :extension) do
        if values[:extension] && values[:file].respond_to?(:path)
          path = values[:file].path
          unless path.end_with?(values[:extension])
            key.failure("must be a #{values[:extension]} file")
          end
        end
      end
    end
  end
end
