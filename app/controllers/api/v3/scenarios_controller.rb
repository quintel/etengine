module Api
  module V3
    class ScenariosController < BaseController
      respond_to :json

      before_action :find_scenario, only: %i[interpolate update]
      around_action :wrap_with_raven_context, only: :update

      before_action :find_preset_or_scenario, only: %i[show merit dashboard]

      authorize_resource except: %i[update]

      rescue_from Scenario::YearInterpolator::InterpolationError do |ex|
        render json: { errors: [ex.message] }, status: :bad_request
      end

      # GET /api/v3/scenarios/:id
      #
      # Returns the scenario details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code
      #
      def show
        render json: ScenarioSerializer.new(self, @scenario, filtered_params)
      end

      # GET /api/v3/scenarios/:id/merit
      #
      # Returns data needed to set up and run an external merit order. Contains
      # information about each producer in the scenario, and the load profiles.
      #
      def merit
        render json: MeritConfigSerializer.new(@scenario.gql.future_graph)
      end

      # GET /api/v3/scenarios/:id1,:id2,:id3,...,:id20/batch
      #
      # Returns the scenarios' details in JSON format. If any of the scenarios
      # is missing, they're not returned.
      #
      def batch
        ids = params[:id].split(',')

        scenarios = Scenario.where(id: ids).includes(:scaler).index_by(&:id)

        @serializers = ids.map do |id|
          scen = Preset.get(id).try(:to_scenario) || scenarios[id.to_i]
          scen ? ScenarioSerializer.new(self, scen, filtered_params) : nil
        end.compact

        render json: @serializers
      end

      def dashboard
        serializer = nil

        Scenario.transaction do
          serializer = ScenarioDashboardSerializer.new(self, @scenario, filtered_params)
        end

        if serializer.errors.any?
          render json: { errors: serializer.errors }, status: 422
        else
          render json: serializer
        end
      end

      # GET /api/v3/scenarios/templates
      #
      # Returns an array of the scenarions with the `in_start_menu`
      # attribute set to true. The ETM uses it on its scenario selection
      # page.
      #
      def templates
        render(json: Preset.visible.map { |ps| PresetSerializer.new(self, ps) })
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

        render json: ScenarioSerializer.new(self, @scenario, filtered_params)
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

        render json: ScenarioSerializer.new(self, @interpolated, {})
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
        final_params = filtered_params.to_h

        authorize!(final_params[:scenario].present? ? :update : :read, @scenario)

        updater    = ScenarioUpdater.for_scenario(@scenario, final_params)
        serializer = nil

        Scenario.transaction do
          updater.apply
          serializer = ScenarioUpdateSerializer.new(self, updater, final_params)

          raise ActiveRecord::Rollback if serializer.errors.any?
        end

        if serializer.errors.any?
          render json: { errors: serializer.errors }, status: 422
        else
          render json: serializer
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
          render json: ScenarioSerializer.new(self, scenario, filtered_params)
        else
          render json: { errors: merger.errors }, status: 422
        end
      rescue ScenarioMerger::Error => ex
        render json: { errors: { base: [ex.message] } }, status: 400
      end

      private

      def find_preset_or_scenario
        @scenario =
          Preset.get(params[:id]).try(:to_scenario) ||
          Scenario.find_for_calculation(params[:id])

        render_not_found(errors: ['Scenario not found']) unless @scenario
      end

      def find_scenario
        @scenario = Scenario.find_for_calculation(params[:id])
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
          :title, user_values: {}, metadata: {}
        ])

        attrs = attrs[:scenario] || {}

        if (user_vals = filtered_user_values(attrs[:scenario])).present?
          attrs[:user_values] = user_vals
        end

        if attrs[:scenario]&.key?(:metadata)
          attrs[:metadata] = filtered_metadata(attrs[:scenario])
        end

        attrs[:descale] = true if attrs[:descale] == 'true'

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

      # Internal: All metadata for the scenario, filtered.
      #
      # Returns a ActionController::Parameters.
      def filtered_metadata(scenario)
        return {} unless scenario&.key?(:metadata)

        scenario[:metadata]
          .permit!
          .to_h
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
