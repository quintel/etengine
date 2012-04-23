module Api
  module V3
    class ScenariosController < ApplicationController
      before_filter :find_scenario, :only => [:show, :update]

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

      # POST /api/v3/scenarios
      #
      # Creates a new scenario
      # TODO: not finished!
      def create
        @scenario = Scenario.new(params[:scenario])
        if @scenario.save
          render :json => @scenario
        else
          render :json => {:errors => @scenario.errors}, :status => 403
        end
      end

      # PUT-PATCH /api/v3/scenarios/:id
      #
      # This is the main scenario interaction method
      #
      # Parameters:
      #
      # - gqueries: array of gquery keys
      # - inputs: hash {input_key: input_value}
      # - reset: boolean (default: false)
      #
      # Response:
      # {
      #   scenario: { ... },
      #   gqueries: {
      #     gquery_key: {
      #       unit: 'foo',
      #       present: 123,
      #       future: 456
      #     },
      #     gquery_other: {
      #       errors: [ 'bad gquery!' ]
      #     }
      #   }
      # }
      #
      def update
        gql = Gql::Gql.new(@scenario)
        gquery_keys = params[:gqueries] || []
        out = Jbuilder.encode do |json|
          json.scenario @scenario
          json.gqueries do |json|
            gquery_keys.each do |k|
              json.set! k do |json|
                if gquery = Gquery.get(k)
                  json.unit gquery.unit
                  json.present(gql.send :query_present, gquery)
                  json.future(gql.send :query_future, gquery)
                else
                  json.errors ["Missing gquery"]
                end
              end
            end
          end
        end
        render :json => out
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
