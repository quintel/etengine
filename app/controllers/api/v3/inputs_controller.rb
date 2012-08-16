module Api
  module V3
    class InputsController < ::Api::V3::BaseController
      before_filter :set_current_scenario, :only => [:index, :show]

      # GET /api/v3/inputs
      # GET /api/v3/scenarios/:scenario_id/inputs
      #
      # Returns the details for all available inputs. If the scenario_id isn't
      # passed then the action will use the latest scenario.
      #
      def index
        render json: (Input.all.each_with_object(Hash.new) do |input, data|
          data[input.key] = InputPresenter.new(input, @scenario)
        end)
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
              InputPresenter.new(fetch_input(id), @scenario, true)
            end
          else
            InputPresenter.new(fetch_input(params[:id]), @scenario, true)
          end

        render json: record
      rescue ActiveRecord::RecordNotFound => e
        render json: { errors: [ e.message ]}, status: 404
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
