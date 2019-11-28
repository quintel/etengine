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
        scenario_attributes.merge(source: 'ETEngine Admin UI')
      )

      update_user_sortables!(
        user_sortable_attributes,
        flexibility_order: @scenario.flexibility_order,
        heat_network_order: @scenario.heat_network_order
      )
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
      @scenario.update!(scenario_attributes)

      update_user_sortables!(
        user_sortable_attributes,
        flexibility_order: @scenario.flexibility_order,
        heat_network_order: @scenario.heat_network_order
      )

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

    attrs.except(:flexibility_order, :heat_network_order)
  end

  def user_sortable_attributes
    params.require(:scenario).permit(
      heat_network_order: [:order],
      flexibility_order: [:order]
    )
  end

  def update_user_sortables!(attrs, records)
    records = records.select { |key, _| attrs.key?(key) }

    records.each do |key, record|
      # Assign the sortable to the scenario explicity, so that we may preserve
      # the object (and errors) when re-rendering the edit view.
      record.scenario.public_send("#{key}=", record)
      record.order = attrs[key][:order].to_s.split
    end

    # Validate each record (to get error message) and raise if any were invalid.
    unless records.reduce(true) { |status, (_, rec)| rec.valid? && status }
      raise ActiveRecord::RecordInvalid
    end

    records.each do |_, record|
      if record.default?
        record.destroy unless record.new_record?
      else
        record.save!(validate: false)
      end
    end
  end
end
