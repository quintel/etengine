# frozen_string_literal: true

module Api
  module V3
    class InputsController < ::Api::V3::BaseController
      before_action do
        @scenario = Scenario.find(params[:scenario_id])
        authorize!(:read, @scenario)
        set_default_format
      end

      # GET /api/v3/inputs
      # GET /api/v3/scenarios/:scenario_id/inputs
      #
      # Returns the details for all available inputs. If the scenario_id isn't
      # passed then the action will use the latest scenario.
      #
      def index
        extras = ActiveModel::Type::Boolean.new.cast(params[:include_extras])

        respond_to do |format|
          format.json do
            render json: InputSerializer.collection(
              Input.all,
              @scenario,
              **serializer_args(extra_attributes: extras)
            )
          end

          format.csv do
            csv_data = CSV.generate(headers: true) do |csv|
              csv << ["Key", "Min value", "Max value", "Default value", "User value", "Unit", "Share group"]
              Input.all.each do |input|
                serializer = InputSerializer.serializer_for(
                  input,
                  @scenario,
                  **serializer_args(extra_attributes: extras)
                )
                csv << serializer.to_csv_row
              end
            end

            send_data csv_data,
                      filename: "scenario_#{@scenario.id}_inputs.csv",
                      type: "text/csv"
          end
        end
      end

      # GET /api/v3/inputs/:id
      # GET /api/v3/scenarios/:scenario_id/inputs/:id
      # GET /api/v3/scenarios/:scenario_id/inputs/:id_1,:id_2,...,:id_N
      #
      # Returns the input details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code.  The inputs
      # are stored in the db and in the etsource, too. At the moment this
      # action uses the DB records. To be updated.
      #
      def show
        record =
          if params.key?(:id) && params[:id].include?(',')
            params[:id].split(',').compact.uniq.map do |id|
              InputSerializer.serializer_for(
                fetch_input(id),
                @scenario,
                **serializer_args(extra_attributes: true)
              )
            end
          else
            InputSerializer.serializer_for(
              fetch_input(params[:id]), @scenario, **serializer_args(extra_attributes: true)
            )
          end

        render json: record
      rescue ActiveRecord::RecordNotFound => e
        render_not_found(errors: [e.message])
      end

      # GET /api/v3/inputs/list.json
      #
      # Returns a JSON-encoded array of inputs. Used to transition from v2 to
      # v3 and replace ids with keys. Can be deleted when all applications
      # will have been upgraded.
      #
      def list
        render json: Input.all.map{|i| {id: i.id, key: i.key}}
      end

      private

      def fetch_input(id)
        (input = Input.get(id)) ? input : raise(ActiveRecord::RecordNotFound)
      end

      def serializer_args(extra_attributes:)
        {
          can_change: current_ability.can?(:update, @scenario),
          default_values_from: params[:defaults] ? params[:defaults].to_sym : :parent,
          extra_attributes:
        }
      end

      def set_default_format
        request.format = :json unless params[:format]
      end
    end
  end
end
