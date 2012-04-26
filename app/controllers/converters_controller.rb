class ConvertersController < ApplicationController
  before_filter :find_graph, :only => :show

  # GET /converters/foobar?api_scenario_id=12345
  # This action is nearly identical to /data/123456/converters/foobar
  # It's kept separate to simplify authorization and views
  def show
    key = params[:id].to_sym
    @converter_present = @gql.present_graph.graph.converter(key)
    @converter_future  = @gql.future_graph.graph.converter(key)
    render :layout => false
  end

  private

  def find_graph
    api_scenario_id = params[:api_scenario_id] ||= 'latest'
    if api_scenario_id == 'latest'
      @api_scenario = Scenario.last
    else
      @api_scenario = Scenario.find(params[:api_scenario_id])
    end
    Current.scenario = @api_scenario
    @gql = @api_scenario.gql(prepare: true)
  end
end
