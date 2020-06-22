module Api
  module V3
    class ScenariosController < BaseController
      respond_to :json

      before_action :find_scenario, only: %i[interpolate update]
      around_action :wrap_with_raven_context, only: :update

      before_action :find_preset_or_scenario, only: [
        :show, :merit, :dashboard, :application_demands,
        :production_parameters, :energy_flow
      ]

      rescue_from Scenario::YearInterpolator::InterpolationError do |ex|
        render json: { errors: [ex.message] }, status: :bad_request
      end

      # GET /api/v3/scenarios/:id
      #
      # Returns the scenario details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code
      #
      def show
        render json: ScenarioPresenter.new(self, @scenario, filtered_params)
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

        scenarios = Scenario.where(id: ids).includes(:scaler).index_by(&:id)

        @presenters = ids.map do |id|
          scen = Preset.get(id).try(:to_scenario) || scenarios[id.to_i]
          scen ? ScenarioPresenter.new(self, scen, filtered_params) : nil
        end.compact

        render json: @presenters
      end

      def dashboard
        presenter = nil

        Scenario.transaction do
          presenter = ScenarioDashboardPresenter.new(self, @scenario, filtered_params)
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

        if attrs.key?(:user_values)
          attrs[:user_values] = attrs[:user_values].transform_values(&:to_f)
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

        render json: ScenarioPresenter.new(self, @scenario, filtered_params)
      rescue ActiveRecord::RecordInvalid
        render json: { errors: @scenario.errors }, status: 422
      end

      # POST /api/v3/scenarios/interpolate
      def interpolate
        @interpolated = Scenario::YearInterpolator.call(
          @scenario, params.require(:end_year).to_i
        )

        @interpolated.protected = true if params[:protected]

        Scenario.transaction do
          @interpolated.save!
        end

        render json: ScenarioPresenter.new(self, @interpolated, {})
      rescue ActionController::ParameterMissing
        render(
          status: :bad_request,
          json: { errors: ['Interpolated scenario must have an end year'] }
        )
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
        updater       = ScenarioUpdater.new(@scenario, filtered_params)
        presenter     = nil

        Scenario.transaction do
          updater.apply

          presenter = ScenarioUpdatePresenter.new(
            self, updater, filtered_params
          )

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
          render json: ScenarioPresenter.new(self, scenario, filtered_params)
        else
          render json: { errors: merger.errors }, status: 422
        end
      rescue ScenarioMerger::Error => ex
        render json: { errors: { base: [ex.message] } }, status: 400
      end

      # GET /api/v3/scenarios/:id/application_demands
      #
      # Returns a CSV file containing the primary and final demands of
      # nodes belonging to the application_group group.
      def application_demands
        send_data(
          ApplicationDemandsPresenter.new(@scenario).as_csv,
          type: 'text/csv',
          filename: "application_demands.#{ @scenario.id }.csv"
        )
      end

      # GET /api/v3/scenarios/:id/production_parameters
      #
      # Returns a CSV file containing the capacities and costs of some
      # electricity and heat producers.
      def production_parameters
        send_data(
          ProductionParametersPresenter.new(@scenario).as_csv,
          type: 'text/csv',
          filename: "production_parameters.#{ @scenario.id }.csv"
        )
      end

      # GET /api/v3/scenarios/:id/energy_flow
      #
      # Returns a CSV file containing the energetic inputs and outputs of every
      # node in the graph.
      def energy_flow
        send_data(
          NodeFlowPresenter.new(@scenario).as_csv,
          type: 'text/csv',
          filename: "energy_flow.#{ @scenario.id }.csv"
        )
      end

      private

      def find_preset_or_scenario
        @scenario =
          Preset.get(params[:id]).try(:to_scenario) ||
          Scenario.find_by_id(params[:id])

        render_not_found(errors: ['Scenario not found']) unless @scenario
      end

      def find_scenario
        @scenario = Scenario.find params[:id]
      rescue ActiveRecord::RecordNotFound
        render_not_found(errors: ['Scenario not found'])
      end

      # Internal: All the request parameters, filtered.
      #
      # Returns a ActionController::Parameters
      def filtered_params
        params.permit(
          :autobalance, :force, :reset, :detailed, :include_inputs, gqueries: []
        ).merge(scenario: scenario_attributes)
      end

      # Internal: Cleaned up attributes for creating and updating scenarios.
      #
      # Returns a ActionController::Parameters.
      def scenario_attributes
        attrs = params.permit(scenario: [
          :area_code, :author, :country, :descale, :description, :end_year,
          :preset_scenario_id, :protected, :region, :scenario_id, :source,
          :title, :use_fce, user_values: {}
        ])

        attrs = (attrs[:scenario] || {}).merge(
          user_values: filtered_user_values(attrs[:scenario])
        )

        attrs[:descale] = attrs[:descale] == 'true'

        attrs
      end

      # Internal: All the user values for a scenario, filtered.
      #
      # Returns a ActionController::Parameters
      def filtered_user_values(scenario)
        return {} unless scenario&.key?(:user_values)

        scenario[:user_values]
          .permit!
          .to_h
          .with_indifferent_access
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

      # Internal: Wraps an action with information about a scenario, so that if
      # an exception occurs, we can provide Sentry with information about the
      # scenario which caused the error.
      #
      # Returns the result of the block.
      def wrap_with_raven_context
        ScenarioRavenContext.with_context(@scenario) { yield }
      end
    end
  end
end
