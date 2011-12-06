class Data::BaseController < ApplicationController
  layout 'data'
  before_filter :find_graph

  authorize_resource :class => false

  def redirect
    redirect_to data_root_path(:api_scenario_id => params[:api_scenario_id])
  end

  protected

    def find_graph
      api_scenario_id = params[:api_scenario_id] ||= 'latest'

      Current.scenario = if api_scenario_id == 'latest'
        @api_scenario = ApiScenario.last
      else
        @api_scenario = ApiScenario.find(params[:api_scenario_id])
      end
      @gql = Current.gql = Gql::Gql.new(Current.scenario)
      @gql.prepare
    end
end
