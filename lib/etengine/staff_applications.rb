# frozen_string_literal: true

module ETEngine
  # Holds config information about OAuth accounts created for staff users.
  module StaffApplications
    class << self
      def applications
        [etmodel, transition_paths]
      end

      def find(key)
        case key.to_sym
        when :etmodel then etmodel
        when :transition_paths then transition_paths
        else raise ArgumentError, "unknown application: #{key}"
        end
      end

      private

      def etmodel
        AppConfig.new(
          key: 'etmodel',
          name: 'ETModel (Local)',
          redirect_uri: 'http://localhost:3000/auth/identity/callback',
          config_path: 'config/settings/settings.local.yml',
          config_content: <<-YAML
            api_url: %<etengine_url>s
            identity:
              client_id: %<client_id>s
              client_secret: %<client_secret>s
              redirect_uri: %<redirect_uri>s
          YAML
        )
      end

      def transition_paths
        AppConfig.new(
          key: 'transition_paths',
          name: 'Transition Paths (Local)',
          config_path: '.env.local',
          config_content: <<-ENV,
            # Protocol and host for ETEngine. No trailing slash please.
            NEXT_PUBLIC_ETENGINE_URL=%<etengine_url>s

            # OAuth client ID for ETEngine.
            NEXT_PUBLIC_AUTH_CLIENT_ID=%<client_id>s
          ENV
          config_epilogue: <<-ENV
            # Protocol and host for ETModel. No trailing slash please.
            NEXT_PUBLIC_ETMODEL_URL=<your etmodel url>
          ENV
        )
      end
    end
  end
end
