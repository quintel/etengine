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

  def merit_order
    @gql.prepare
  end

  def gquery
    @gql.sandbox_mode = :debug
    @gql.init_datasets
    @gql.update_graphs

    # Run the custom defined input
    if params[:input_yml].andand.present? && params[:input_user_value]
      input      = Input.load_yaml(params[:input_yml])
      user_value = params[:input_user_value]
      @gql.update_graph(:future, input, user_value)
    end

    @gql.calculate_graphs

    if params[:gquery].andand.present?
      @gql.query("OBSERVE_GET(ALL())")
      @gql.query(params[:gquery])
    end

    @logs = (@gql.future_graph.logger.logs || []).compact.flatten
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