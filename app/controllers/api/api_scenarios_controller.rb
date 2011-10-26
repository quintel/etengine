class Api::ApiScenariosController < ApplicationController
  layout 'api'

  around_filter :disable_gc, :only => [:update, :show]

  before_filter :find_model, :only => [:destroy, :user_values]

  def index
    @api_scenarios = ApiScenario.order('updated_at DESC')

    respond_to do |format|
      format.html {  }
      format.json { render :json => @api_scenarios, :callback => params[:callback] }
    end
  end

  def new
    attributes = ApiRequest.new_attributes(params[:settings])
    @api_scenario = ApiScenario.create!(attributes)

    respond_to do |format|
      format.html { redirect_to api_scenario_url(@api_scenario.id)}
      format.json { render :json => @api_scenario, :callback => params[:callback] }
    end
  end
  # create does the same like new, except that it is a POST request
  alias_method :create, :new

  ##
  # This is the main API entry point. Most operations happen through this method.
  # The ETM slider updates and gquery requests are processed here. See ApiRequest.
  #
  # Available parameters:
  # * id: id of the scenario we're querying
  # * input: a hash with input_id as key and value as value
  # * r: a string that joins gquery ids with ApiRequest::GQUERY_KEY_SEPARATOR
  # * result: array of gquery keys/ids
  # * reset: will first clear the scenario attributes
  #
  # The purpose of the shorter r parameter is to have shorter URLs. IE will truncate
  # too long JSONP requests. If we hadn't the cross-domain issue we could send
  # everything with a simple JSON POST request.
  #
  def show
    @api_request = ApiRequest.response(params)
    @api_scenario = @api_request.scenario
    @api_response = @api_request.response

    respond_to do |format|
      format.html { render }
      format.json { render :json => @api_response, :callback => params[:callback] }
    end
  end
  # update does the same like show, but it is a POST request
  alias_method :update, :show

  def destroy
    @api_scenario.destroy
    redirect_to api_scenarios_url
  end

  def user_values
    @api_request = ApiRequest.response(params)
    Current.scenario = @api_request.scenario
    
    values = Rails.cache.fetch("inputs.user_values.#{Current.graph.id}") do
      Input.static_values
    end

    Input.dynamic_start_values.each do |id, dynamic_values|
      values[id.to_s][:start_value] = dynamic_values[:start_value] if values[id.to_s]
    end

    @api_scenario.user_values.each do |id, user_value|
      values[id.to_s][:user_value] = user_value if values[id.to_s]
    end
    respond_to do |format|
      format.json do
        render :json => values, :callback => params[:callback] 
      end
    end
  end

  protected

    def find_model
      @api_scenario = ApiScenario.find(params[:id])
    end

end
