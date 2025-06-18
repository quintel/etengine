module CurveHandler
  module Services
    class DestroyService < BaseService
      def call
        cfg = find_config!
        if (uc = scenario.attached_curve(cfg.db_key))
          DetachService.call(uc)
        end
        Result.new
      end
    end
  end
end
