class Backend::ScenariosController < Backend::BaseController
  layout 'application'

  before_action :find_scenario, :only => [:show, :edit, :update]

  def index
    base = Scenario.recent_first
    if params[:q]
      if params[:q] =~ /^\d+$/
        base = base.by_id(params[:q])
      else
        base = base.by_name(params[:q]) if params[:q]
      end
    end
    base = base.in_start_menu if params[:in_start_menu]
    base = base.where(:protected => true) if params[:protected]
    @scenarios = base.page(params[:page]).per(35)
  end

  def new
    @scenario = Scenario.new(Scenario.default_attributes)
  end

  def create
    @scenario = Scenario.new(scenario_attributes.merge(source: 'ETEngine Admin UI'))

    if @scenario.save
      redirect_to backend_scenario_path(:id => @scenario.id), :notice => 'Scenario created'
    else
      render :new
    end
  end

  def show
    respond_to do |format|
      format.html

      format.ad do
        render(
          plain: Preset.from_scenario(@scenario).to_active_document,
          layout: nil,
          content_type: 'text/x-active-document'
        )
      end
    end
  end

  def edit
  end

  def update
    if @scenario.update_attributes(scenario_attributes)
      redirect_to backend_scenario_path(:id => @scenario.id), :notice => 'Scenario updated'
    else
      render :edit
    end
  end

  private

  def find_scenario
    if params[:id] == 'current'
      @scenario = @api_scenario
    else
      @scenario = Scenario.find params[:id]
    end
  end

  def scenario_attributes
    attrs = params.require(:scenario).permit!
    attrs[:protected] = attrs[:protected] == '1'

    attrs
  end
end
