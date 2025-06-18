module CurveHandler
  module Services
    class UpdateService < BaseService
      def call
        cfg     = find_config!
        upload  = params.require(:file)
        handler = AttachService.new(cfg, upload, scenario, metadata)

        if handler.valid?
          uc   = handler.call
          json = cfg.serializer.new(uc).as_json
          Result.new(json: json)
        else
          Result.new(errors: handler.errors, error_keys: handler.error_keys)
        end
      end
    end
  end
end
