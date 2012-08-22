module Api
  module V3
    class ScenariosController < BaseController
      respond_to :json

      before_filter :find_scenario, :only => [:show, :update, :sandbox]

      # GET /api/v3/scenarios/:id
      #
      # Returns the scenario details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code
      #
      def show
        render json: ScenarioPresenter.new(self, @scenario, params[:detailed])
      end

      # GET /api/v3/scenarios/templates
      #
      # Returns an array of the scenarions with the `in_start_menu`
      # attribute set to true. The ETM uses it on its scenario selection
      # page.
      #
      def templates
        render json: Preset.all.map { |ps| PresetPresenter.new(self, ps) }
      end

      # POST /api/v3/scenarios
      #
      # Creates a new scenario. This action is used when a user on the ETM
      # saves a scenario, too: in that case a copy of the scenario is saved.
      #
      def create
        attrs = Scenario.default_attributes.merge(params[:scenario] || {})

        if attrs.key?(:scenario_id) || attrs.key?(:preset_scenario_id)
          # If user_values is assigned after the preset ID, we would wipe out
          # the preset user values.
          attrs.delete(:user_values)
        end

        @scenario = Scenario.new(attrs)

        if @scenario.save
          # With HTTP 201 nginx doesn't set content-length or chunked encoding
          # headers
          render json: ScenarioPresenter.new(self, @scenario), status: 200
        else
          render json: { errors: @scenario.errors }, status: 422
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
        updater   = ScenarioUpdater.new(@scenario, params)
        presenter = nil

        Scenario.transaction do
          updater.apply
          presenter = ScenarioUpdatePresenter.new(self, updater, params)

          raise ActiveRecord::Rollback if presenter.errors.any?
        end

        if presenter.errors.any?
          render json: { errors: presenter.errors }, status: 422
        else
          render json: presenter
        end
      end

      # GET /api/v3/scenarios/:id/sandbox
      #
      # Returns the gql details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code.
      #
      def sandbox
        if params[:gql].present?
          @query = params[:gql].gsub(/\s/,'')
        else
          render :json => {:errors => 'No gql'}, :status => 500 and return
        end

        begin
          gql = @scenario.gql(prepare: true)
          result = gql.query(@query)
        rescue Exception => e
          render :json => {:errors => [e.to_s]}, :status => 500 and return
        end

        out = Jbuilder.encode do |json|
          if result.respond_to?(:present_year)
            json.present_year result.present_year
            json.present_value result.present_value.inspect
            json.future_year result.future_year
            json.future_value result.future_value.inspect
          else
            json.result result
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

    end
  end
end
