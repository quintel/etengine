module Api
  module V3
    class ScenariosController < BaseController

      rescue_from Scenario::YearInterpolator::InterpolationError do |ex|
        render json: { errors: [ex.message] }, status: :bad_request
      end

      load_resource except: %i[show create destroy dump]
      load_and_authorize_resource class: Scenario, only: %i[index show create destroy dump]

      before_action only: %i[batch] do
        # Only check that the user can read. We restrict the search in the action.
        authorize!(:read, Scenario)
      end

      before_action only: %i[create] do
        # Authorize create here because we load the resource explicity in the action
        authorize!(:update, Scenario)
      end

      before_action only: %i[dashboard merit] do
        authorize!(:read, @scenario)
      end

      before_action only: %i[interpolate] do
        authorize!(:clone, @scenario)
      end

      before_action only: %i[couple uncouple] do
        authorize!(:update, @scenario)
      end

      around_action :wrap_with_sentry_context, only: :update

      # GET /api/v3/scenarios
      #
      # Lists all scenarios belonging to the current user.
      #
      def index
        unless current_user
          render(
            json: { errors: ['You must be authenticated to access this resource'] },
            status: :forbidden
          )
          return
        end

        scenarios = Scenario
          .accessible_by(current_ability)
          .viewable_by?(current_user)
          .order(created_at: :desc)
          .page((params[:page].presence || 1).to_i)
          .per((params[:limit].presence || 25).to_i.clamp(1, 100))

        render json: PaginationSerializer.new(
          collection: scenarios,
          serializer: ->(item) { ScenarioSerializer.new(self, item) },
          url_for: ->(page, limit) { api_v3_scenarios_url(page:, limit:) }
        )
      end

      # GET /api/v3/scenarios/:id
      #
      # Returns the scenario details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code
      #
      def show
        render json: ScenarioSerializer.new(self, @scenario)
      end

      # GET /api/v3/scenarios/:id/merit
      #
      # Returns data needed to set up and run an external merit order. Contains
      # information about each producer in the scenario, and the load profiles.
      #
      def merit
        render json: MeritConfigSerializer.new(
          @scenario.gql.future_graph, include_curves: include_curves_in_merit?
        )
      end

      # GET /api/v3/scenarios/:id1,:id2,:id3,...,:id20/batch
      #
      # Returns the scenarios' details in JSON format. If any of the scenarios
      # is missing, they're not returned.
      #
      def batch
        ids = params[:id].split(',')

        scenarios = Scenario.accessible_by(current_ability)
          .where(id: ids).includes(:users, :scaler)

        @serializers = scenarios.map do |scenario|
          ScenarioSerializer.new(self, scenario)
        end

        render json: @serializers
      end

      def dashboard
        serializer = nil

        Scenario.transaction do
          serializer = ScenarioDashboardSerializer.new(self, @scenario, filtered_params)
        end

        if serializer.errors.any?
          render json: { errors: serializer.errors }, status: :unprocessable_entity
        else
          render json: serializer
        end
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

        attrs = Scenario.default_attributes.merge(scenario_params || {})
        parent = nil

        if attrs.key?(:scenario_id) || attrs.key?(:preset_scenario_id)
          parent = Scenario.find_by(id: attrs[:scenario_id] || attrs[:preset_scenario_id])

          unless parent && can?(:read, parent)
            render(
              json: { errors: { scenario_id: ['does not exist'] } },
              status: :unprocessable_entity
            )
            return
          end

          # If user_values is assigned after the preset ID, we would wipe out
          # the preset user values.
          attrs.delete(:user_values)

          # Inherit the visibility if no explicity visibility is set.
          attrs[:private] = parent.clone_should_be_private?(current_user) if attrs[:private].nil?
        elsif current_user && attrs[:private].nil?
          attrs[:private] = current_user.private_scenarios?
        end

        if attrs.key?(:user_values)
          attrs[:user_values] = attrs[:user_values].transform_values(&:to_f)
        end

        @scenario = Scenario.new

        if scaler_attributes && !attrs[:descale]
          scaler = @scenario.build_scaler(scaler_attributes)

          if parent&.scaler
            scaler.base_value = parent.scaler.base_value
          elsif parent
            scaler.set_base_with(parent)
          end
        end

        # Check for coupling groups in the inputs and activate them
        if attrs[:user_values]
          scenario_updater = ScenarioUpdater.new(@scenario, attrs[:user_values], current_user)
          scenario_updater.activate_coupling_groups
        end

        # The scaler needs to be in place before assigning attributes when the
        # scenario inherits from a preset.
        @scenario.descale    = attrs[:descale]
        @scenario.attributes = attrs

        if current_user.present?
          @scenario.scenario_users << ScenarioUser.new(
            scenario: @scenario,
            user: current_user,
            role_id: User::ROLES.key(:scenario_owner)
          )
        end

        Scenario.transaction do
          @scenario.save!
        end

        render json: ScenarioSerializer.new(self, @scenario)
      rescue ActiveRecord::RecordInvalid
        render json: { errors: @scenario.errors }, status: :unprocessable_entity
      end

      # POST /api/v3/scenarios/interpolate
      def interpolate
        @interpolated = Scenario::YearInterpolator.call(
          @scenario, params.require(:end_year).to_i, current_user
        )

        Scenario.transaction do
          @interpolated.save!
        end

        render json: ScenarioSerializer.new(self, @interpolated)
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

        if final_params[:scenario].blank?
          authorize!(:read, @scenario)
        elsif final_params[:scenario][:set_preset_roles].present?
          authorize!(:destroy, @scenario)
        else
          authorize!(:update, @scenario)
        end

        updater    = ScenarioUpdater.new(@scenario, final_params, current_user)
        serializer = nil

        Scenario.transaction do
          updater.apply
          serializer = ScenarioUpdateSerializer.new(self, updater, final_params)

          raise ActiveRecord::Rollback if serializer.errors.any?
        end

        if serializer.errors.any?
          render json: { errors: serializer.errors }, status: :unprocessable_entity
        else
          render json: serializer
        end
      end

      # DELETE /api/v3/scenarios/:id
      #
      # Deletes a scenario.
      def destroy
        current_user.scenarios.find(params[:id]).destroy
        head :ok
      end

      # GET /api/v3/scenarios/merge
      #
      # Merges two or more scenarios.
      #
      def merge
        authorize!(:create, Scenario)

        merge_params = params.permit(scenarios: %i[scenario_id weight])

        merge_params[:scenarios].each do |scenario|
          authorize!(:read, Scenario.find(scenario[:scenario_id]))
        end

        if (merger = ScenarioMerger.from_params(merge_params)).valid?
          scenario = merger.merged_scenario
          scenario.save

          # redirect_to api_v3_scenario_url(scenario)
          render json: ScenarioSerializer.new(self, scenario)
        else
          render json: { errors: merger.errors }, status: :unprocessable_entity
        end
      rescue ScenarioMerger::Error => e
        render json: { errors: { base: [e.message] } }, status: :bad_request
      end

      # POST /api/v3/scenarios/:id/couple
      #
      # Uncouples the specified groups in the scenario. When the force parameter is passed,
      # removes all coupled inputs from any coupling from the scenario
      #
      def uncouple
        if coupling_parameters[:force]
          force_uncouple
        else
          coupling_parameters[:groups].each { |coupling| @scenario.deactivate_coupling(coupling.to_s) }
          if @scenario.save
            render json: ScenarioSerializer.new(self, @scenario)
          else
            render json: { errors: @scenario.errors.messages }, status: :unprocessable_entity
          end
        end
      end

      # POST /api/v3/scenarios/:id/couple
      #
      # Couples the specified groups in the scenario.
      #
      def couple
        coupling_parameters[:groups].each { |coupling| @scenario.activate_coupling(coupling.to_s) }
        if @scenario.save
          render json: ScenarioSerializer.new(self, @scenario)
        else
          render json: { errors: @scenario.errors.messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v3/scenarios/:id/dump
      def dump
        render json: ScenarioPacker::Dump.new(@scenario)
      end

      # POST /api/v3/scenarios/:id/load_dump
      def load_dump
        unless current_user&.admin?
          render(
            json: { errors: ['You must be authenticated to load dumps'] },
            status: :forbidden
          )
          return
        end

        render json: ScenarioSerializer.new(self, ScenarioPacker::Load.new(params.permit!).scenario)
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
          :autobalance, :force, :reset, gqueries: []
        ).merge(scenario: scenario_params)
      end

      # Internal: Cleaned up attributes for creating and updating scenarios.
      #
      # Returns a ActionController::Parameters.
      def scenario_params
        attrs = params.permit(scenario: [
          :area_code,
          :descale,
          :end_year,
          :keep_compatible,
          :preset_scenario_id,
          :private,
          :scenario_id,
          :set_preset_roles,
          :source,
          { user_values: {} },
          { metadata: {} }
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
        return unless params[:scenario] && params[:scenario][:scale]

        params[:scenario].require(:scale).permit(
          :area_attribute, :value,
          :has_agriculture, :has_energy, :has_industry
        )
      end

      # Internal: Parameters for coupling and uncoupling
      #
      # Returns a ActionController::Parameters.
      def coupling_parameters
        params.permit(:force, groups: [])
      end

      # Internal: Parameters for the merit config
      #
      # Returns a ActionController::Parameters.
      def merit_parameters
        params.permit(:include_curves)
      end

      # Internal: Checks if curves should be included in the merit config
      #
      # Returns a Bool
      def include_curves_in_merit?
        merit_parameters[:include_curves] != 'false'
      end

      def force_uncouple
        serializer = nil

        updater = ScenarioUpdater.new(
          @scenario,
          { uncouple: coupling_parameters[:force], scenario: {} },
          current_user
        )

        Scenario.transaction do
          updater.apply
          serializer = ScenarioUpdateSerializer.new(self, updater, {})

          raise ActiveRecord::Rollback if serializer.errors.any?
        end

        if serializer.errors.any?
          render json: { errors: serializer.errors }, status: :unprocessable_entity
        else
          render json: serializer
        end
      end

      # Internal: Wraps an action with information about a scenario, so that if
      # an exception occurs, we can provide Sentry with information about the
      # scenario which caused the error.
      #
      # Returns the result of the block.
      def wrap_with_sentry_context
        ScenarioSentryContext.with_context(@scenario) { yield }
      end
    end
  end
end
