# frozen_string_literal: true

module Api
  module V3
    # TEMPORARY(legacy-pat): a personal access token (PAT), as sent by pyETM 2.0, carries no grant.
    # With grants only, a PAT request on one bound Session takes its grant from MyETM. Removed
    # when the engine stops accepting PATs directly.
    module LegacyPatFallback
      CACHE_TTL = 30.minutes
      REVOKED_TTL = 2.hours
      REQUEST_OPTIONS = { timeout: 2, open_timeout: 2 }.freeze

      private

      # The grant MyETM holds for the PAT's user on the requested Session, or nil
      def legacy_pat_access
        ScenarioAccess.new(cached_legacy_grant) if legacy_pat_session_id
      end

      def legacy_pat_session_id
        return @legacy_pat_session_id if defined?(@legacy_pat_session_id)

        @legacy_pat_session_id = legacy_pat && !current_user.admin? && bound_session_id
      end

      # A batch route names several Sessions, which is no Integer, so it is skipped
      def bound_session_id
        id = Integer(requested_session_id, exception: false)
        id if id && Scenario.exists?(id:, bound: true)
      end

      def requested_session_id
        path = request.path_parameters
        return path[:scenario_id] if path.key?(:scenario_id)
        return unless controller_path.in?(%w[api/v3/scenarios api/v3/export])

        path[:id] || copied_session_id
      end

      # The source when creating a Session from another, or from a preset
      def copied_session_id
        source = params[:scenario]
        return unless action_name == 'create' && source.is_a?(ActionController::Parameters)

        source[:scenario_id] || source[:preset_scenario_id]
      end

      # The Authorization header
      def legacy_pat
        token = request.authorization.to_s[/\ABearer (.+)\z/, 1]
        token if token&.start_with?('etm_')
      end

      # Failures are not cached, so the next request asks again. A PAT MyETM refuses (revoked or
      # expired) can never be accepted again, so the refusal is cached for 2 hours
      def cached_legacy_grant
        return if Rails.cache.exist?(legacy_pat_key(:revoked))

        Rails.cache.fetch(legacy_pat_key(legacy_pat_session_id), expires_in: CACHE_TTL) do
          fetch_legacy_grant.tap { report_legacy_pat_use }
        end
      rescue Faraday::UnauthorizedError
        Rails.cache.write(legacy_pat_key(:revoked), true, expires_in: REVOKED_TTL)
        nil
      rescue Faraday::Error => e
        Rails.logger.warn("Legacy PAT grant lookup failed: #{e.class}")
        nil
      end

      def legacy_pat_key(suffix)
        ['legacy-pat', Digest::SHA256.hexdigest(legacy_pat), suffix]
      end

      def fetch_legacy_grant
        client = my_etm_client
        client.options.merge!(REQUEST_OPTIONS)

        path = "/api/v2/legacy_grants/#{Settings.version_tag}/#{legacy_pat_session_id}"
        client.get(path).body['data']
      end

      # Sentry lists who still sends PATs. Cached answers are not reported, bounding the volume.
      def report_legacy_pat_use
        Sentry.capture_message('Legacy PAT request', level: :info) do |scope|
          scope.set_user(id: current_user.id, email: current_user.email)
          scope.set_extras(scenario_id: legacy_pat_session_id)
        end
      end
    end
  end
end
