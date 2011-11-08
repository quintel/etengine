class Data::ScenariosController < Data::BaseController
  before_filter :find_scenario, :only => :show
  
  def index
    @scenarios = Scenario.page(params[:page]).per(35)
  end

  def show
  end
  
  private
  
    def find_scenario
      @scenario = Scenario.find params[:id]
    end
end
