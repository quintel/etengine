module CurveHandler
  module Services
    class ShowService < BaseService
      def call
        cfg        = find_config!
        uc         = find_curve!(cfg)
        raw_series = uc.curve.to_a
        series     = process(raw_series, uc, cfg)
        json       = cfg.serializer.new(uc).as_json
        filename   = "\#{uc.name || uc.key}.csv"

        Result.new(series: series, filename: filename, json: json)
      end
    end
  end
end
