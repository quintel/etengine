module CurveHandler
  class Result
    attr_reader :series, :filename, :json, :errors, :error_keys

    def initialize(series: nil, filename: nil, json: nil, errors: nil, error_keys: nil)
      @series     = series
      @filename   = filename
      @json       = json
      @errors     = errors
      @error_keys = error_keys
    end

    def csv_data
      return unless series
      CSV.generate { |csv| series.each { |v| csv << [v] } }.chomp
    end
  end
end
