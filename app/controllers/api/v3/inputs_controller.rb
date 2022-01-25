module Api
  module V3
    class InputsController < ::Api::V3::BaseController
      before_action do
        @scenario = Scenario.find(params[:scenario_id])
        authorize!(:read, @scenario)
      end

      # GET /api/v3/inputs
      # GET /api/v3/scenarios/:scenario_id/inputs
      #
      # Returns the details for all available inputs. If the scenario_id isn't
      # passed then the action will use the latest scenario.
      #
      def index
        extras = params[:include_extras]
        render json: InputSerializer.collection(Input.all, @scenario, extras)
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
              InputSerializer.serializer_for(fetch_input(id), @scenario, true)
            end
          else
            InputSerializer.serializer_for(
              fetch_input(params[:id]), @scenario, true
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

      #######
      private
      #######

      def fetch_input(id)
        (input = Input.get(id)) ? input : raise(ActiveRecord::RecordNotFound)
      end

    end # InputsController
  end # V3
end # Api
