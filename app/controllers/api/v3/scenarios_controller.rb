module Api
  module V3
    class ScenariosController < ApplicationController
      before_filter :find_scenario, :only => :show

      # GET /api/v3/scenarios/:id
      #
      # Returns the scenario details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code
      #
      def show
        render :json => @scenario
      end

      # GET /api/v3/scenarios/templates
      #
      # Returns an array of the scenarions with the `in_start_menu`
      # attribute set to true. The ETM uses it on its scenario selection
      # page.
      #
      def templates
        @scenarios = Scenario.in_start_menu
        render :json => @scenarios
      end

      private

      def find_scenario
        @scenario = Scenario.find params[:id]
      rescue ActiveRecord::RecordNotFound
        render :json => {}, :status => 404 and return
      end
    end
  end
end
