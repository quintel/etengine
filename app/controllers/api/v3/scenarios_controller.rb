module Api
  module V3
    class ScenariosController < BaseController
      respond_to :json

      before_filter :find_scenario, :only => [:show, :update]

      # GET /api/v3/scenarios/:id
      #
      # Returns the scenario details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code
      #
      def show
        detailed = params[:detailed].present?
        out = Jbuilder.encode do |json|
          scenario_to_jbuilder(@scenario, json, detailed)
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
        @presets = Preset.all
        out = Jbuilder.encode do |json|
          json.array!(@presets) do |json, preset|
            # include description
            preset_to_jbuilder(preset, json, true)
          end
        end
        render :json => out
      end

      # POST /api/v3/scenarios
      #
      # Creates a new scenario. This action is used when a user on the ETM saves
      # a scenario, too: in that case a copy of the scenario is saved.
      #
      def create
        @scenario = Scenario.new(params[:scenario])
        @scenario.title ||= 'API'

        if @scenario.save
          out = Jbuilder.encode do |json|
            scenario_to_jbuilder(@scenario, json)
          end
          # With HTTP 201 nginx doesn't set content-length or chunked encoding
          # headers
          render :json => out, :status => 200
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
          unless params[:reset]
            attrs[:user_values].reverse_merge!(@scenario.user_values)
          end
        end
        # TODO: handle scenario ownership!
        @scenario.update_attributes(attrs)
        begin
          @scenario.input_errors = []
          gql = @scenario.gql(prepare: true)
        rescue Exception => e
          # TODO: Scenario#gql should raise helpful exceptions.
          render :json => {:errors => [e.to_s]}, :status => 500 and return
        end
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
          if @scenario.input_errors.any?
            json.errors @scenario.input_errors
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

      def scenario_to_jbuilder(s, json, detailed_info = false)
        json.title      s.title
        json.url        api_v3_scenario_url(s)
        json.id         s.id
        json.area_code  s.area_code
        json.end_year   s.end_year
        json.template   s.preset_scenario_id
        json.source     s.source
        json.created_at s.created_at
        if detailed_info
          json.description s.description
          json.use_fce s.use_fce
        end
      end


      def preset_to_jbuilder(preset, json, include_description = false)
        json.id        preset.id
        json.title     preset.title
        json.url       api_v3_scenario_url(preset)
        json.area_code preset.area_code
        json.end_year  preset.end_year
        json.template  nil
        json.source    nil
        if include_description
          json.description preset.description
        end
      end
    end
  end
end
