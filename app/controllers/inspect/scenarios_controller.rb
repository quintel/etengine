class Inspect::ScenariosController < Inspect::BaseController
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
    Scenario.transaction do
      @scenario = Scenario.create!(
        scenario_attributes
          .except(:flexibility_order)
          .merge(source: 'ETEngine Admin UI')
      )

      update_flexibility_order!(@scenario, scenario_attributes)
    end

    redirect_to inspect_scenario_path(id: @scenario.id), notice: 'Scenario created'
  rescue ActiveRecord::RecordInvalid
    render :new
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
    Scenario.transaction do
      @scenario.update!(scenario_attributes.except(:flexibility_order))
      update_flexibility_order!(@scenario, scenario_attributes)

      redirect_to inspect_scenario_path(id: @scenario.id), notice: 'Scenario updated'
    end
  rescue ActiveRecord::RecordInvalid
    render :edit
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

  def update_flexibility_order!(scenario, attrs)
    return unless attrs[:flexibility_order]

    fo = scenario.flexibility_order || scenario.build_flexibility_order
    fo.order = attrs[:flexibility_order][:order].to_s.split

    if fo.order == FlexibilityOrder.default_order || fo.order.empty?
      fo.destroy unless fo.new_record?
    else
      fo.save!
    end
  end
end
