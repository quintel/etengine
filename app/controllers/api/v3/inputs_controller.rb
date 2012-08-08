module Api
  module V3
    class InputsController < ::Api::V3::BaseController
      before_filter :set_current_scenario, :only => [:index, :show]
      before_filter :find_input, :only => :show

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
      #
      # Returns the input details in JSON format. If the scenario is missing
      # the action returns an empty hash and a 404 status code.  The inputs
      # are stored in the db and in the etsource, too. At the moment this action
      # uses the DB records. To be updated.
      #
      def show
        render json: InputPresenter.new(@input, @scenario, true)
      end

      private

      def find_input
        @input = Input.get(params[:id])
      rescue Exception => e
        render :json => {:errors => [e.message]}, :status => 404 and return
      end

    end # InputsController
  end # V3
end # Api
