class Data::DebugController < Data::BaseController
  layout 'application'

  def calculation
    @gql.init_datasets
    @gql.update_present
    @gql.present_graph.calculate

    @gql.future.query("OBSERVE_SET(ALL(), demand)")
    @gql.update_future
    @gql.future_graph.calculate
    @gql.calculated = true

    @logs = (@gql.future.graph.logger.logs || []).compact.flatten
  end

  def gquery
    @gql.prepare
    @gql.sandbox_mode = :debug
    @gql.query("OBSERVE_GET(ALL(), demand)")
    if params[:gquery]
      @gql.query(params[:gquery])
    end
    @logs = (@gql.future.graph.logger.logs || []).compact.flatten
  end

  def initialize_gql
    api_scenario_id = params[:api_scenario_id] ||= 'latest'

    if api_scenario_id == 'latest'
      @api_scenario = Scenario.last
    else
      @api_scenario = Scenario.find(params[:api_scenario_id])
    end
    @gql = @api_scenario.gql(prepare: false)
  end
end