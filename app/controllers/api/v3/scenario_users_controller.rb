# frozen_string_literal: true

module Api
  module V3
    class ScenarioUsersController < BaseController
      include UsesScenario

      SUNSET = Date.new(2027, 3, 1).httpdate
      RETIREMENT_NOTICE =
        'Scenario users endpoints are deprecated and will be removed ' \
        'at the end of February 2027. ' \
        "Manage scenario access in MyETM: #{Settings.identity.issuer}".freeze

      prepend_before_action :render_gone
      # Prepended after render_gone so it runs first and the 410 carries it as well
      prepend_before_action :announce_sunset

      # Only scenario owners, having the delete authority, may manage scenario users
      before_action { authorize!(:destroy, @scenario) }

      def index; end

      def create; end

      def update; end

      def destroy; end

      def destroy_all; end

      private

      def render_gone
        render status: :gone, json: { errors: [RETIREMENT_NOTICE] }
      end

      def announce_sunset
        response.set_header('Sunset', SUNSET)
        response.set_header('Deprecation-Notice', RETIREMENT_NOTICE)
      end
    end
  end
end
