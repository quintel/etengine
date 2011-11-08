# This controller is mostly used for ActiveResource requests
#
class Api::ScenariosController < ApplicationController
  respond_to :xml
  
  before_filter :find_scenario, :only => [:show, :load, :update]

  def index
    @scenarios = Scenario.exclude_api.recent_first.page(params[:page]).per(20)
    respond_with(@scenarios)
  end
  
  # ETM makes use of this action
  #
  def homepage
    respond_with(@scenarios = Scenario.where(:in_start_menu => true))
  end

  def show
    @scenario = @scenario.try(:clone!) if params[:clone]
    if @scenario
      respond_with(@scenario)
    else
      render :text => 'record missing', :status => 404
    end
  end

  def create
    api_session_id = params[:scenario].delete("api_session_id")
    api_session_id ||= params[:scenario].delete("api_session_key") # legacy remove after 2011-10

    if api_session_id
      api_scenario = ApiScenario.find(api_session_id)
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
      @scenario = Scenario.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn "*** ActiveResource 404 Error"
      nil
    end
end