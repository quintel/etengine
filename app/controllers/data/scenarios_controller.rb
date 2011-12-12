class Data::ScenariosController < Data::BaseController
  before_filter :find_scenario, :only => [:show, :fix, :edit, :update]
  
  def index
    base = Scenario.scoped
    base = base.by_name(params[:q]) if params[:q]
    base = base.in_start_menu if params[:in_start_menu]
    @scenarios = base.page(params[:page]).per(35)
  end
  
  def new
    @scenario = Scenario.new
  end

  def show
  end
  
  def edit
  end
  
  def update
    if @scenario.update_attributes(params[:scenario])
      redirect_to data_scenario_path(:id => @scenario.id), :notice => 'Scenario updated'
    else
      render :edit
    end
  end
  
  def fix
    if params[:force]    
      @scenario.update_hh_inputs!
      flash.now[:notice] = "Scenario updated!"
    end
  end
  
  private
  
    def find_scenario
      @scenario = Scenario.find params[:id]
    end
end
