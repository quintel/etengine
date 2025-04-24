class Inspect::ScenariosController < Inspect::BaseController
  layout 'application'

  before_action :find_scenario, :only => [:show, :edit, :update]

  def index
    @list_params = params.permit(:api_scenario_id, :q, :page)
    base = Scenario.recent_first.includes(:users)
    base = base.by_id(@list_params[:q]) if @list_params[:q].present?
    @scenarios = base.page(@list_params[:page]).per(100)
  end

  def new
    @scenario = Scenario.new(Scenario.default_attributes)
  end

  def create
    Scenario.transaction do
      @scenario = Scenario.new

      Scenario::Editable.new(@scenario).update!(
        scenario_attributes.merge(source: 'ETEngine Admin UI')
      )

      update_user_sortables!(
        user_sortable_attributes,
        forecast_storage_order: @scenario.forecast_storage_order,
        hydrogen_supply_order: @scenario.hydrogen_supply_order,
        hydrogen_demand_order: @scenario.hydrogen_demand_order,
        heat_network_order_ht: @scenario.heat_network_order(:ht),
        heat_network_order_mt: @scenario.heat_network_order(:mt),
        heat_network_order_lt: @scenario.heat_network_order(:lt),
        households_space_heating_producer_order: @scenario.households_space_heating_producer_order
      )
    end

    redirect_to inspect_scenario_path(id: @scenario.id), notice: 'Scenario created'
  rescue ActiveRecord::RecordInvalid
    render :new
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def edit
  end

  def update
    Scenario.transaction do
      @scenario.update!(scenario_attributes)

      update_user_sortables!(
        user_sortable_attributes,
        forecast_storage_order: @scenario.forecast_storage_order,
        heat_network_order_ht: @scenario.heat_network_order(:ht),
        heat_network_order_mt: @scenario.heat_network_order(:mt),
        heat_network_order_lt: @scenario.heat_network_order(:lt),
        households_space_heating_producer_order: @scenario.households_space_heating_producer_order
      )

      redirect_to inspect_scenario_path(id: @scenario.id), notice: 'Scenario updated'
    end
  rescue ActiveRecord::RecordInvalid
    render :edit
  end

  def load_dump
    unless current_user.admin?
      redirect_to root_path
      return
    end

    json_data = JSON.parse(File.read(params.permit(:dump)[:dump].path)).with_indifferent_access
    scenario = ScenarioPacker::Load.new(json_data).scenario
    redirect_to inspect_scenario_path(id: scenario.id), notice: 'Scenario created'
  end

  private

  def find_scenario
    if params[:id] == 'current'
      @scenario = @api_scenario
    else
      @scenario = Scenario::Editable.new(Scenario.find(params[:id]))
    end
  end

  def scenario_attributes
    params.require(:scenario).permit!.except(
      :forecast_storage_order,
      :hydrogen_supply_order,
      :hydrogen_demand_order,
      :heat_network_order_ht,
      :heat_network_order_mt,
      :heat_network_order_lt,
      :households_space_heating_producer_order
    )
  end

  def user_sortable_attributes
    params.require(:scenario).permit(
      forecast_storage_order: [:order],
      hydrogen_supply_order: [:order],
      hydrogen_demand_order: [:order],
      heat_network_order_ht: [:order],
      heat_network_order_mt: [:order],
      heat_network_order_lt: [:order],
      households_space_heating_producer_order: [:order]
    )
  end

  def update_user_sortables!(attrs, records)
    records = records.select { |key, _| attrs.key?(key) }

    records.each do |key, record|
      # Assign the sortable to the scenario explicity, so that we may preserve
      # the object (and errors) when re-rendering the edit view.
      record.scenario.public_send("#{key}=", record) if record.scenario.respond_to?("#{key}=")
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
