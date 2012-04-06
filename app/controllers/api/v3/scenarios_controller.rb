module Api
  module V3
    class ScenariosController < ApplicationController
      before_filter :find_scenario

      def show
        out = Jbuilder.encode do |json|
          json.id @scenario.id
          json.title @scenario.title
        end
        render :text => out
      end

      private

      def find_scenario
        @scenario = Scenario.find params[:id]
      end
    end
  end
end
