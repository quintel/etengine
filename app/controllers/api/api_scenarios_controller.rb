class Api::ApiScenariosController < ApplicationController
  layout 'api'

  around_filter :disable_gc, :only => [:update, :show]

  before_filter :find_model, :only => [:update, :show, :destroy, :user_values]

  def index
    @api_scenarios = ApiScenario.order('updated_at DESC')

    respond_to do |format|
      format.html {  }
      format.json { render :json => @api_scenarios, :callback => params[:callback] }
    end
  end

  def new
    @api_scenario = ApiScenario.create!(new_attributes)
    respond_to do |format|
      format.html { redirect_to api_scenario_url(@api_scenario.api_session_key)}
      format.json { render :json => @api_scenario, :callback => params[:callback] }
    end
  end
  # create does the same like new, except that it is a POST request
  alias_method :create, :new

  ##
  # GET result[]=gquery_key&result[]=gquery_key2
  # 335=2.4&421=2.9
  def show 
    Current.scenario = @api_scenario
    # RD: why are we using a update command inside the show method?
    # SB: - this updates the scenario with the submitted slider values params[:input]
    #     - the API is a GET show request, so that we can use it with JSON-P
    update_scenario(@api_scenario) 
    @results = results
    @json = {
      'result'   => @results,
      'settings' => @api_scenario.serializable_hash(:only => [:api_session_key, :user_values, :country, :region, :start_year, :end_year, :use_fce, :preset_scenario_id])
      
      #, 'errors'   => @api_scenario.api_errors(test_scenario?)
    }

    respond_to do |format|
      format.html { render }
      format.json { render :json => @json, :callback => params[:callback] }
    end
  end
  # update does the same like show, but it is a POST request
  alias_method :update, :show

  def destroy
    @api_scenario.destroy
    redirect_to api_scenarios_url
  end

  def user_values
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

  ##
  # Is alias to show.
  #
  def find_model
    if test_scenario?
      @api_scenario = ApiScenario.new(new_attributes)
    else
      @api_scenario = ApiScenario.find_by_api_session_key(params[:id])
    end
  end

  private

    def test_scenario?
      params[:id] == 'test'
    end

    def new_attributes
      settings = params[:settings].present? ? params[:settings] : {}
      settings.each do |key,value|
        settings[key] = nil if value == 'null' or key == 'undefined'
      end
      ApiScenario.new_attributes(settings)
    end

    def results
      if params[:result] || params[:r]
        # split by ";" because "," is url encoded into 3 characters.
        results = [params[:result], params[:r].andand.split(';')]
        results.flatten!
        results.compact!
        results.map!(&:to_s) # key could be passsed as integer with json(P)
        results.reject!(&:blank?)

        invalid_result = Gql::ResultSet::INVALID
        @gqueries = results.inject({}) do |hsh, key|
          if key == "null" or key == "undefined"
            hsh
          elsif gquery = (Gquery.get(key) rescue nil)
            if gquery.converters?
              hsh.merge(key => (Current.gql.query(gquery) rescue invalid_result))
            else
              hsh
            end
          else
            if key.include?('(')
              hsh.merge(key => (Current.gql.query(key) rescue invalid_result))
            else
              hsh.merge(key => invalid_result)
            end
          end
        end
      else
        @gqueries = nil
      end
    end

    def update_scenario(scenario)
      scenario.reset! if params[:reset]
      if params[:input]
        scenario.update_inputs_for_api(params[:input])
        # Save scenario with new user_values, except it is a test version
        scenario.save unless test_scenario?
      end
      
      if params[:use_fce]
        # If the use_fce setting has changed it should be updated. this influences emission calculations
        scenario.use_fce = params[:use_fce] 
        scenario.save unless test_scenario? || !scenario.changed?
      end
    end
end
