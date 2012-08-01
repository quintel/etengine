module Api
  module V3
    class InputsController < BaseController
      before_filter :set_current_scenario, :only => [:index, :show]
      before_filter :find_input, :only => :show

      # GET /api/v3/inputs
      # GET /api/v3/scenarios/:scenario_id/inputs
      #
      # Returns the details for all available inputs. If the scenario_id isn't
      # passed then the action will use the latest scenario. There is no caching
      # yet.
      def index
        @inputs = Input.all
        out = Jbuilder.encode do |json|
          @inputs.each do |i|
            json.set! i.key do |json|
              unless i.share_group.blank?
                json.share_group i.share_group
              end
              json.max i.max_value_for(@gql)
              json.min i.min_value_for(@gql)
              json.default i.start_value_for(@gql)
              json.disabled true if i.disabled_in_current_area?(@gql)
              if label = i.full_label_for(@gql)
                json.label label
              end
              if user_value = @scenario.user_values[i.key || i.id]
                json.user user_value
              end
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
        out = Jbuilder.encode do |json|
          json.code @input.key
          unless @input.share_group.blank?
            json.share_group @input.share_group
          end
          json.max @input.max_value_for(@gql)
          json.min @input.min_value_for(@gql)
          json.default @input.start_value_for(@gql)
          json.disabled true if @input.disabled_in_current_area?(@gql)
          if label = @input.full_label_for(@gql)
            json.label label
          end
          if user_value = @scenario.user_values[@input.id]
            json.user user_value
          end

        end
        render :json => out
      end

      private

      def find_input
        @input = Input.get(params[:id])
      rescue Exception => e
        render :json => {:errors => [e.message]}, :status => 404 and return
      end
    end
  end
end
