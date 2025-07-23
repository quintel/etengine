module CurveHandler
  module Serializers
    class BaseSerializer

      def initialize(scenario, params, metadata = {})
        @scenario = scenario
        @params   = params
        @metadata = metadata
      end

      private

      attr_reader :scenario, :params, :metadata

      # Fetch keys of all curves attached to the scenario
      def attached_keys
        @attached_keys ||= scenario.attached_curve_keys
      end

      # Retrieve a specific UserCurve by its database key
      def user_curve(db_key)
        scenario.attached_curve(db_key)
      end

      # Cast parameter to boolean (handles strings, etc.)
      def bool(key)
        !!ActiveModel::Type::Boolean.new.cast(params[key])
      end

      # Look up the curve configuration, stripping the "_curve" suffix
      def find_config!
        Config.find(params[:id].to_s.chomp('_curve'))
      end

      # Find an existing, loadable UserCurve or raise if not found
      def find_curve!(cfg)
        uc = user_curve(cfg.db_key)
        raise ActiveRecord::RecordNotFound unless uc&.loadable_curve?
        uc
      end

      # Post-process raw data (e.g., rescaling for capacity profiles)
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
