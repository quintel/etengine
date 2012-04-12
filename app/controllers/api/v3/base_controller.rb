module Api
  module V3
    class BaseController < ApplicationController

      protected

      # Many API actions require an active scenario. Let's set it here
      # and let's prepare the field for the calculations.
      #
      def set_current_scenario
        if params[:scenario_id]
          @scenario = ApiScenario.find(params[:scenario])
        else
          @scenario = ApiScenario.last
        end
        # this setup is ugly, we should find a simpler way to prepare all
        # we need. The scenario object should be able to set up all the
        # gql, future/present stuff. I'd like to get rid of the Current
        # object, too.
        #
        Current.scenario = @scenario
        @gql = @scenario.gql(:prepare => true)
      rescue ActiveRecord::RecordNotFound
        render :json => {:errors => ["Scenario not found"]}, :status => 404 and return
      end
    end
  end
end
