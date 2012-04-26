# This controller is mostly used for ActiveResource requests. Check ApiScenariosController
# to see how the API requests work.
#
class Api::ScenariosController < Api::BaseController
  respond_to :xml

  before_filter :find_scenario, :only => [:show, :load, :update]

  def index
    @scenarios = Scenario.exclude_api.recent_first.page(params[:page]).per(20)
    respond_with(@scenarios)
  end

  # ETM makes use of this action to fill the preset scenarios select box
  #
  def homepage
    respond_with(@scenarios = Scenario.where(:in_start_menu => true))
  end

  def show
    # Are we still using the :clone parameter? - PZ Thu 1 Dec 2011 15:41:08 CET
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
      api_scenario = Scenario.find(api_session_id)
      @scenario = api_scenario.save_as_scenario(params[:scenario])
    else
      #@scenario = Scenario.new(params[:scenario])
      #@scenario.save
    end
    respond_with(@scenario)
  end

  # Is this still used?
  # PZ - Thu 17 Nov 2011 15:22:02 CET
  def update
    @scenario.update_attributes(params[:scenario])
    respond_with(@scenario)
  end

  # Is this still used?
  # PZ - Thu 17 Nov 2011 15:22:02 CET
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
