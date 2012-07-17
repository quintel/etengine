class Data::DebugController < Data::BaseController
  layout 'etsource'

  def calculation
    @gql.init_datasets
    @gql.update_present
    @gql.present_graph.calculate
    
    @gql.future.query("OBSERVE(ALL(), demand)")
    @gql.update_future
    @gql.future_graph.calculate
    @gql.calculated = true

    @logs = @gql.future.query("MAP(GRAPH(), observe_log)").compact.flatten
  end

  def gquery
    @gql.prepare
    #@gql.query("OBSERVE_GET(OUTPUT_LINKS(ALL()), demand)")
    @gql.query("OBSERVE_GET(ALL(), demand)")
    @gql.query("Q(security_of_supply_loss_of_load_probability)")
    @logs = (@gql.future.graph.logger.logs || []).compact.flatten
  end

  def initialize_gql
    api_scenario_id = params[:api_scenario_id] ||= 'latest'

    if api_scenario_id == 'latest'
      @api_scenario = Scenario.last
    else
      @api_scenario = Scenario.find(params[:api_scenario_id])
    end
    @gql = @api_scenario.gql(prepare: false, sandbox_mode: :debug)
  end
end