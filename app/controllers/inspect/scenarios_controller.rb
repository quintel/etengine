class Inspect::ScenariosController < Inspect::BaseController
  layout 'application'

  before_action :find_scenario, :only => [:show, :edit, :update]

  def index
    @list_params = params.permit(:api_scenario_id, :q, :api_read_only, :page)
    base = Scenario.recent_first
    base = base.by_id(@list_params[:q]) if @list_params[:q].present?
    # rubocop:disable Rails/WhereEquals
    # Use interpolation since `api_read_only: true` creates SQL which matches on equality with
    # `TRUE` rather than `1`.
    base = base.where('api_read_only = ?', true) if @list_params[:api_read_only]
    # rubocop:enable Rails/WhereEquals
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
    end
  end

  def edit
  end

  def update
    Scenario.transaction do
      @scenario.update!(scenario_attributes)

      update_user_sortables!(
        user_sortable_attributes,
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
      @scenario = Scenario::Editable.new(Scenario.find(params[:id]))
    end
  end

  def scenario_attributes
    params.require(:scenario).permit!.except(:heat_network_order)
  end

  def user_sortable_attributes
    params.require(:scenario).permit(
      heat_network_order: [:order]
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
