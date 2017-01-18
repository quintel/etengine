module Api
  module V3
    class ScenariosController < BaseController
      respond_to :json

      before_filter :find_scenario, only: [:update, :sandbox]
      before_filter :find_preset_or_scenario, only: [:show, :merit, :dashboard]

      # GET /api/v3/scenarios/:id
      #
      # Returns the scenario details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code
      #
      def show
        render json: ScenarioPresenter.new(self, @scenario, params)
      end

      # GET /api/v3/scenarios/:id/merit
      #
      # Returns data needed to set up and run an external merit order. Contains
      # information about each producer in the scenario, and the load profiles.
      #
      def merit
        render json: MeritConfigPresenter.new(@scenario.gql.future_graph)
      end

      # GET /api/v3/scenarios/:id1,:id2,:id3,...,:id20/batch
      #
      # Returns the scenarios' details in JSON format. If any of the scenarios
      # is missing, they're not returned.
      #
      def batch
        ids = params[:id].split(',')

        @scenarios = ids.map do |id|
          scenario = Preset.get(id).try(:to_scenario) || Scenario.find_by_id(id)
          scenario ? ScenarioPresenter.new(self, scenario, params) : nil
        end.compact

        render json: @scenarios
      end

      def dashboard
        presenter = nil

        Scenario.transaction do
          presenter = ScenarioDashboardPresenter.new(self, @scenario, params)
        end

        if presenter.errors.any?
          render json: { errors: presenter.errors }, status: 422
        else
          render json: presenter
        end
      end

      # GET /api/v3/scenarios/templates
      #
      # Returns an array of the scenarions with the `in_start_menu`
      # attribute set to true. The ETM uses it on its scenario selection
      # page.
      #
      def templates
        render(json: Preset.visible.map { |ps| PresetPresenter.new(self, ps) })
      end

      # POST /api/v3/scenarios
      #
      # Creates a new scenario. This action is used when a user on the ETM
      # saves a scenario, too: in that case a copy of the scenario is saved.
      #
      def create
        # Weird ActiveResource bug: the user values attribute is nested inside
        # another user_values hash. Used when generating a scenario with the
        # average values of other scenarios.
        inputs = params[:scenario][:user_values]["user_values"] rescue nil
        if inputs
          params[:scenario][:user_values] = inputs
        end

        attrs = Scenario.default_attributes.merge(scenario_attributes || {})

        if attrs.key?(:scenario_id) || attrs.key?(:preset_scenario_id)
          # If user_values is assigned after the preset ID, we would wipe out
          # the preset user values.
          attrs.delete(:user_values)
        end

        @scenario = Scenario.new

        if scaler_attributes && ! attrs[:descale]
          scaler = @scenario.build_scaler(scaler_attributes)

          if parent_id = attrs[:scenario_id] || attrs[:preset_scenario_id]
            if parent = Scenario.find_by_id(parent_id)
              if parent.scaler
                scaler.base_value = parent.scaler.base_value
              else
                scaler.set_base_with(parent)
              end
            end
          end
        end

        # The scaler needs to be in place before assigning attributes when the
        # scenario inherits from a preset.
        @scenario.descale    = attrs[:descale]
        @scenario.attributes = attrs

        Scenario.transaction do
          @scenario.save!
        end

        render json: ScenarioPresenter.new(self, @scenario, params)
      rescue ActiveRecord::RecordInvalid
        render json: { errors: @scenario.errors }, status: 422
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
        updater_attrs = params.merge(scenario: scenario_attributes)
        updater       = ScenarioUpdater.new(@scenario, updater_attrs)
        presenter     = nil

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

      # GET /api/v3/scenarios/merge
      #
      # Merges two or more scenarios.
      #
      def merge
        merge_params = params.permit(scenarios: [:scenario_id, :weight])

        if (merger = ScenarioMerger.from_params(merge_params)).valid?
          scenario = merger.merged_scenario
          scenario.save

          # redirect_to api_v3_scenario_url(scenario)
          render json: ScenarioPresenter.new(self, scenario, params)
        else
          render json: { errors: merger.errors }, status: 422
        end
      rescue ScenarioMerger::Error => ex
        render json: { errors: { base: [ex.message] } }, status: 400
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

        json =
          if result.respond_to?(:present_year)
            { present_year:  result.present_year,
              present_value: result.present_value,
              future_year:   result.future_year,
              future_value:  result.future_value }
          else
            { result: result }
          end

        render json: json
      end

      private

      def find_preset_or_scenario
        @scenario = Preset.get(params[:id]).try(:to_scenario) ||
                    Scenario.find_by_id(params[:id])
        render :json => {:errors => ["Scenario not found"]}, :status => 404 and return unless @scenario
      end

      def find_scenario
        @scenario = Scenario.find params[:id]
      rescue ActiveRecord::RecordNotFound
        render :json => {:errors => ["Scenario not found"]}, :status => 404 and return
      end

      # Internal: Cleaned up attributes for creating and updating scenarios.
      #
      # Returns a hash.
      def scenario_attributes
        attrs = (params[:scenario] || {}).slice(
          :author, :title, :description, :user_values, :end_year, :area_code,
          :country, :region, :preset_scenario_id, :use_fce, :protected,
          :scenario_id, :source, :user_values, :descale
        )

        attrs['descale'] = attrs['descale'] == 'true'

        attrs
      end

      # Internal: Attributes for creating a scaled scenario.
      #
      # Returns a hash.
      def scaler_attributes
        if params[:scenario] && params[:scenario][:scale]
          params[:scenario].require(:scale).permit(
            :area_attribute, :value,
            :has_agriculture, :has_energy, :has_industry
          )
        end
      end
    end
  end
end
