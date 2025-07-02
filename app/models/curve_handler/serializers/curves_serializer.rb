module CurveHandler
  module Serializers
    class CurvesSerializer < BaseSerializer
      def call
        available = Etsource::Config.user_curves.values
        available = available.reject(&:internal?) unless bool(:include_internal)

        curves = available.map do |cfg|
          if attached_keys.include?(cfg.db_key)
            cfg.serializer.new(user_curve(cfg.db_key)).as_json
          elsif bool(:include_unattached)
            UnattachedCustomCurveSerializer.new(cfg).as_json
          end
        end.compact

        Result.new(series: curves)
      end
    end
  end
end
