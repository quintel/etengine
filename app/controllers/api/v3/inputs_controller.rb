module Api
  module V3
    class InputsController < BaseController
      before_filter :set_current_scenario, :only => [:index, :show]
      before_filter :find_input, :only => :show

      # GET /api/v3/inputs
      # GET /api/v3/scenarios/:scenario_id/inputs
      #
      # Returns the details for all available inputs. If the scenario_id isn't
      # passed then the action will use the latest scenario. The action is now
      # using the existing user_values action, so the response is in the old
      # format.
      #
      def index
        @inputs = Input.all
        gql = @scenario.gql
        out = Jbuilder.encode do |json|
          @inputs.each do |i|
            json.set! i.id do |json|
              json.code i.key
              json.share_group i.share_group
              json.max i.max_value_for(gql) rescue nil
              json.min i.min_value_for(gql) rescue nil
              json.default i.start_value_for(gql) rescue nil
              json.disabled true if i.disabled_in_current_area?
              json.label label if label = i.full_label_for(gql) rescue nil
            end
          end
        end
        render :json => out
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
        render :json => @input
      end

      private

      def find_input
        @input = Api::V3::Input.find(params[:id])
      rescue Exception => e
        render :json => {:errors => [e.message]}, :status => 404 and return
      end
    end
  end
end
