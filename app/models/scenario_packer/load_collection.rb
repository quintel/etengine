# frozen_string_literal: true

module ScenarioPacker
  class LoadCollection
    include Dry::Monads[:result]

    # Large max file size for now while we only expect this to be used locally
    MAX_FILE_SIZE = 5000.megabytes

    attr_reader :scenarios

    # Builds & loads straight from an uploaded file object
    #
    # @param [ActionDispatch::Http::UploadedFile] file
    # @return [Dry::Monads::Result]
    def self.from_file(file)
      new([])
        .validate_file(file)
        .bind { |content| new([]).parse_file_content(content) }
        .bind { |data| new(data).call }
    end

    def initialize(data_array)
      @data_array = data_array
      @scenarios  = []
    end

    def call
      results = @data_array.map { |d| Load.new(d).call }

      # Collect failures
      failures = results.select(&:failure?)
      return Failure(failures.map(&:failure)) if failures.any?

      # Extract successful scenarios
      @scenarios = results.map(&:value!)
      Success(LoadResult.new(@scenarios))
    end

    def validate_file(file)
      contract = Contracts::FileUploadContract.new
      result = contract.call(file: file)

      if result.success?
        Success(file)
      else
        Failure(result.errors.to_h)
      end
    end

    def parse_file_content(file)
      file_size = File.size(file.path)

      return Failure('file is empty') if file_size.zero?
      return Failure("file too large (max #{MAX_FILE_SIZE / 1.megabyte}MB)") if file_size > MAX_FILE_SIZE

      content = File.read(file.path)
      JsonParser.parse(content)
        .fmap { |raw| raw.is_a?(Array) ? raw : [raw] }
        .fmap { |data| data.map(&:with_indifferent_access) }
    rescue StandardError => e
      Failure("Failed to read file: #{e.message}")
    end

    def first_id
      scenarios.first&.id
    end

    def single?
      scenarios.one?
    end

    # Result value object for load collection operation
    LoadResult = Struct.new(:scenarios) do
      def first_id
        scenarios.first&.id
      end

      def single?
        scenarios.one?
      end

      def count
        scenarios.count
      end
    end
  end
end
