class ConvertersController < ApplicationController
  before_filter :find_graph, :only => :show

  def show
    key = params[:id].to_sym
    converter_id = Converter.full_keys[key]
    @converter = Converter.find converter_id
    @converter_present = @gql.present_graph.graph.converter(key)
    @converter_future  = @gql.future_graph.graph.converter(key)
    render :layout => false
  end

  private

  def find_graph
    # TODO: ETM should pass the right scenario id or, at least, the country
    # DEBT: Data::BaseController has an identical method
    api_scenario_id = params[:api_scenario_id] ||= 'latest'
    if api_scenario_id == 'latest'
      @api_scenario = ApiScenario.last
    else
      @api_scenario = ApiScenario.find(params[:api_scenario_id])
    end
    Current.scenario = @api_scenario
    @gql = @api_scenario.gql(prepare: true)
  end
end
