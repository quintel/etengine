class Data::ScenariosController < Data::BaseController
  layout 'application'

  before_filter :find_scenario, :only => [:show, :edit, :update]

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
    respond_to do |format|
      format.html
      format.yml { render :text =>  @scenario.to_yaml, :content_type => "application/x-yaml"}
    end
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

  private

  def find_scenario
    @scenario = Scenario.find params[:id]
  end
end
