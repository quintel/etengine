class Data::BaseController < ApplicationController
  layout 'data'
  before_filter :initialize_gql

  authorize_resource :class => false

  def redirect
    redirect_to data_root_path(:api_scenario_id => params[:api_scenario_id])
  end

  protected

    def initialize_gql
      api_scenario_id = params[:api_scenario_id] ||= 'latest'

      if api_scenario_id == 'latest'
        @api_scenario = Scenario.last
      else
        @api_scenario = Scenario.find(params[:api_scenario_id])
      end
      @gql = @api_scenario.gql(prepare: true)
    rescue Atlas::DocumentNotFoundError => ex
      if ex.message.match(/could not find a dataset with the key/i)
        scenario = Scenario.create(
          Scenario.default_attributes.merge(source: 'ETEngine Admin UI'))

        redirect_to "/data/#{ scenario.id }"
      else
        raise ex
      end
    end
end
