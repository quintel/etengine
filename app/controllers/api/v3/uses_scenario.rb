# frozen_string_literal: true

module Api
  module V3
    # A module which may be included in a controller which handles a scenario relation. Asserts that
    # the user has permission to perform an action on a scenario.
    #
    # UsesScenario maps action names to scenario abilities:
    #
    #   index, show => read
    #   new, create => create
    #   edit, update => update
    #   destroy => update
    #
    # Note that destroy is mapped to update, since removing a relation from a scenario is akin to
    # updating the scenario.
    module UsesScenario
      def self.included(base)
        base.before_action(:authorize_scenario!)

        base.rescue_from(ActiveRecord::RecordNotFound) do |ex|
          raise ex unless ex.model == Scenario.name

          render json: { errors: ['Scenario not found'] }, status: 404
        end
      end

      def authorize_scenario!
        authorize!(action_name == 'destroy' ? :update : action_name.to_sym, scenario)
      end

      def scenario
        @scenario ||= Scenario.find(params[:scenario_id])
      end
    end
  end
end
