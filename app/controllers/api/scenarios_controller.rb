class Api::ScenariosController < ApplicationController
  respond_to :xml
  
  before_filter :find_scenario, :only => [:show, :load, :update]

  def index
    @scenarios = Scenario.exclude_api.recent_first.page(params[:page]).per(20)
    respond_with(@scenarios)
  end
  
  def homepage
    respond_with(@scenarios = Scenario.where(:in_start_menu => true))
  end

  def show
    if params[:clone]
      @scenario = @scenario.clone!
    end    
    respond_with(@scenario)
  end

  def create
    if api_session_key = params[:scenario].delete("api_session_key")
      api_scenario = ApiScenario.find_by_api_session_key(api_session_key)
      @scenario = api_scenario.save_as_scenario(params[:scenario])
    else
      #@scenario = Scenario.new(params[:scenario])
      #@scenario.save
    end
    respond_with(@scenario)
  end

  def update
    @scenario.update_attributes(params[:scenario])
    respond_with(@scenario)
  end

  def load
    respond_with(@scenario.load!)
  end

  private
    def find_scenario
      # DEBT
      @scenario = Scenario.find_by_api_session_key(params[:id]) || Scenario.find(params[:id])
    end
end