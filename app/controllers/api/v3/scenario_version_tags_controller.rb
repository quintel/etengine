module Api
  module V3
    class ScenarioVersionTagsController < BaseController
      include UsesScenario

      skip_before_action :authorize_scenario!, :only => :index

      before_action :validate_scenario_version_tag, only: :update

      # GET api/v3/scenarios/:id/version
      def show
        render json: ScenarioVersionSerializer.new(scenario)
      end

      # GET api/v3/scenarios/versions
      #
      # Lists all version tags of all the scenarios if they have one,
      # indexed on the scenario_ids
      def index
        version_params = params.permit(scenarios: [])
        ids = version_params[:scenarios].map(&:to_i)

        scenarios = Scenario.accessible_by(current_ability)
          .where(id: ids).includes(:users, :scenario_version_tag)

        @serializers = scenarios.each_with_object({}) do |scenario, hash|
          hash[scenario.id] = ScenarioVersionSerializer.new(scenario)

          hash
        end

        render json: @serializers
      end

      # POST api/v3/scenarios/:id/version
      def create
        version = ScenarioVersionTag.new(
          description: version_params[:description],
          user: current_user,
          scenario: scenario
        )

        version.save

        render json: ScenarioVersionSerializer.new(scenario)
      rescue ActiveRecord::RecordNotUnique
        render(
          status: :unprocessable_entity,
          json: { errors: ['A version was already tagged'] }
        )
      end

      # PUT api/v3/scenarios/:id/version
      def update
        if version_params[:description]
          scenario_version_tag.description = version_params[:description]
        end

        if scenario_version_tag.save
          render json: ScenarioVersionSerializer.new(scenario)
        else
          render(
            status: :unprocessable_entity,
            json: { errors: version.errors.messages }
          )
        end
      end

      private

      # Allow old and new way of structuring params
      def version_params
        if params['scenario_version_tag']
          params.require(:scenario_version_tag).permit(:description)
        else
          params.permit(:description)
        end
      end

      def scenario_version_tag
        @scenario_version_tag ||= scenario.scenario_version_tag
      end

      def validate_scenario_version_tag
        return if scenario_version_tag.present?

        render(
          status: :not_found,
          json: { errors: ['Scenario version tag not found'] }
        )
      end
    end
  end
end
