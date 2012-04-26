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
        out = Jbuilder.encode do |json|
          scenario_to_jbuilder(@scenario, json)
        end

        render :json => out
      end

      # GET /api/v3/scenarios/templates
      #
      # Returns an array of the scenarions with the `in_start_menu`
      # attribute set to true. The ETM uses it on its scenario selection
      # page.
      #
      def templates
        @scenarios = Scenario.in_start_menu
        out = Jbuilder.encode do |json|
          json.array!(@scenarios) do |json, s|
            scenario_to_jbuilder(s, json)
          end
        end
        render :json => out
      end

      # POST /api/v3/scenarios
      #
      # Creates a new scenario
      # TODO: not finished!
      def create
        @scenario = Scenario.new(params[:scenario])
        @scenario.title ||= 'API'
        if @scenario.save
          out = Jbuilder.encode do |json|
            scenario_to_jbuilder(@scenario, json)
          end
          render :json => out, :status => 201
        else
          render :json => {:errors => @scenario.errors}, :status => 422
        end
      end

      # PUT-PATCH /api/v3/scenarios/:id
      #
      # This is the main scenario interaction method
      #
      # Parameters:
      #
      # - gqueries: array of gquery keys
      # - scenario: scenario attributes
      # - reset: boolean (default: false)
      #
      # Example request parameters:
      #
      # {
      #   scenario: {
      #     user_values: {
      #       123: 1.34
      #     }
      #   },
      #   gqueries: ['gquery_a', 'gquery_b']
      # }
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
        # TODO: move parameter logic to a separate object
        attrs = params[:scenario] || {}
        # TODO: handle int/string keys
        if attrs[:user_values]
          attrs[:user_values].reverse_merge!(@scenario.user_values)
        end
        # TODO: handle scenario ownership!
        @scenario.update_attributes(attrs)
        gql = @scenario.gql(:prepare => true)
        gquery_keys = params[:gqueries] || []
        out = Jbuilder.encode do |json|
          json.scenario do |json|
            scenario_to_jbuilder(@scenario, json)
          end
          json.gqueries do |json|
            gquery_keys.each do |k|
              json.set! k do |json|
                if gquery = Gquery.get(k)
                  # this logic should be moved to a separate object. Will do as
                  # soon as we decide the final output format
                  json.unit gquery.unit
                  errors = []
                  begin
                    pres_result = gql.send(:query_present, gquery)
                    json.present pres_result
                  rescue Exception => e
                    json.present nil
                    errors << e.to_s
                  end
                  # TODO: DRY
                  begin
                    fut_result = gql.send(:query_future, gquery)
                    json.future fut_result
                  rescue Exception => e
                    json.future nil
                    errors << e.to_s
                  end
                  json.errors errors unless errors.empty?
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
        render :json => {:errors => ["Scenario not found"]}, :status => 404 and return
      end

      # TODO: move to model
      def scenario_to_jbuilder(s, json)
          json.title     s.title
          json.url       api_v3_scenario_url(s)
          json.id        s.id
          json.area_code s.area_code
          json.end_year  s.end_year
          json.template  s.preset_scenario_id
          json.source    nil
      end
    end
  end
end
