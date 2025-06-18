module CurveHandler
  module Services
    class BaseService
      def initialize(scenario, params, metadata = {})
        @scenario = scenario
        @params   = params
        @metadata = metadata
      end

      private

      attr_reader :scenario, :params, :metadata

      def attached_keys
        @attached_keys ||= scenario.attached_curve_keys
      end

      def user_curve(db_key)
        scenario.attached_curve(db_key)
      end

      def bool(key)
        ActiveModel::Type::Boolean.new.cast(params[key])
      end

      def find_config!
        Config.find(params[:id].to_s.chomp('_curve'))
      end

      def find_curve!(cfg)
        uc = user_curve(cfg.db_key)
        raise ActiveRecord::RecordNotFound unless uc&.loadable_curve?
        uc
      end

      def process(raw, uc, cfg)
        return raw unless cfg.processor_key == :capacity_profile

        key = cfg.input_keys.last
        flh = uc.scenario.user_values[key]
        return raw unless flh

        Reducers::Rescaler.new(raw, flh).call
      end
    end
  end
end
