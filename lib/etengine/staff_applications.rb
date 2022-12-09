# frozen_string_literal: true

module ETEngine
  # Holds config information about OAuth accounts created for staff users.
  module StaffApplications
    class << self
      def all
        [etmodel]
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
          scopes: 'openid email profile public scenarios:read scenarios:write scenarios:delete',
          uri: 'http://localhost:3001',
          redirect_path: '/auth/identity/callback',
          run_command: 'bundle exec rails server -p %<port>s',
          config_path: 'config/settings/settings.local.yml',
          config_content: <<~YAML,
            api_url: %<etengine_url>s

            auth:
              client_id: %<uid>s
              client_secret: %<secret>s
              client_uri: %<uri>s
          YAML
          config_epilogue: <<~YAML
            multi_year_charts_url: <multi year charts url (optional)>
          YAML
        )
      end

      def transition_paths
        AppConfig.new(
          key: 'transition_paths',
          name: 'Transition Paths (Local)',
          scopes: 'openid email profile public scenarios:read scenarios:write scenarios:delete',
          uri: 'http://localhost:3005',
          run_command: 'yarn dev -p %<port>s',
          config_path: '.env.local',
          config_content: <<~ENV,
            # Protocol and host for ETEngine. No trailing slash please.
            NEXT_PUBLIC_ETENGINE_URL=%<etengine_url>s

            # OAuth client credentials for ETEngine.
            NEXT_PUBLIC_AUTH_CLIENT_ID=%<uid>s
            NEXT_PUBLIC_AUTH_CLIENT_SECRET=%<secret>s
          ENV
          config_epilogue: <<~ENV
            # Protocol and host for ETModel. No trailing slash please.
            NEXT_PUBLIC_ETMODEL_URL=<your etmodel url>
          ENV
        )
      end
    end
  end
end
