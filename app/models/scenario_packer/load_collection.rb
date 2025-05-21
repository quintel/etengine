# frozen_string_literal: true

module ScenarioPacker
  class LoadCollection
    attr_reader :scenarios

    # Builds & loads straight from an uploaded file object
    #
    # @param [ActionDispatch::Http::UploadedFile] file
    # @return [LoadCollection]
    def self.from_file(file)
      raise ArgumentError, 'No file provided' unless file.respond_to?(:path)

      raw = JSON.parse(File.read(file.path))
      data = raw.is_a?(Array) ? raw : [raw]
      loader = new(data.map(&:with_indifferent_access))
      loader.load_all
      loader
    end

    def initialize(data_array)
      @data_array = data_array
      @scenarios  = []
    end

    def load_all
      @scenarios = @data_array.map { |d| Load.new(d).scenario }
    end

    def first_id
      scenarios.first&.id
    end

    def single?
      scenarios.one?
    end
  end
end
