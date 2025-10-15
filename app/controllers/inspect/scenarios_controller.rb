# frozen_string_literal: true

module Inspect
  class ScenariosController < BaseController
    layout 'application'

    load_and_authorize_resource only: %i[load_dump dump], class: 'Scenario'
    before_action :find_scenario, only: %i[show edit update]
    skip_before_action :initialize_gql, only: %i[load_dump dump]

    # Lists recent scenarios with optional search and pagination
    def index
      @list_params = params.permit(:api_scenario_id, :q, :page)
      base = Scenario.recent_first.includes(:users)
      base = base.by_id(@list_params[:q]) if @list_params[:q].present?
      @scenarios = base.page(@list_params[:page]).per(100)
    end

    # Renders form for creating a new scenario
    def new
      @scenario = Scenario.new(Scenario.default_attributes)
    end

    # Creates a new scenario with attributes and user sortables
    def create
      scenario = Scenario.new(Scenario.default_attributes.merge(source: 'ETEngine Admin UI'))
      @scenario = Scenario::Editable.new(scenario)

      # Parse editable attributes and return early if parsing fails
      return redirect_to new_inspect_scenario_path unless parse_editable_attributes(new_inspect_scenario_path)

      apply_scenario_changes(
        scenario,
        success_path: inspect_scenario_path(id: scenario.id),
        failure_path: new_inspect_scenario_path,
        success_notice: 'Scenario created',
        render_on_invalid: :new
      )
    end

    # Shows a single scenario
    def show
      respond_to(&:html)
    end

    # Renders form for editing an existing scenario
    def edit; end

    # Updates a scenario and its user sortables
    def update
      # Get the underlying scenario model for orchestrator
      underlying_scenario = @scenario.__getobj__

      # Parse editable attributes and return early if parsing fails
      return redirect_to edit_inspect_scenario_path(id: underlying_scenario.id) unless parse_editable_attributes(edit_inspect_scenario_path(id: underlying_scenario.id))

      apply_scenario_changes(
        underlying_scenario,
        success_path: inspect_scenario_path(id: underlying_scenario.id),
        failure_path: edit_inspect_scenario_path(id: underlying_scenario.id),
        success_notice: 'Scenario updated',
        render_on_invalid: :edit
      )
    end

    # Loads one or more scenarios from a JSON dump file
    def load_dump
      loader = ScenarioPacker::LoadCollection.from_file(dump_file_param)
      if loader.single?
        redirect_to inspect_scenario_path(
          id: loader.first_id,
          api_scenario_id: loader.first_id
        ), notice: 'Scenario created'
      else
        @api_scenario = Scenario.find(loader.first_id)
        @scenario     = Scenario::Editable.new(@api_scenario)
        @scenarios    = loader.scenarios
        render :load_results
      end
    rescue ArgumentError
      redirect_back(fallback_location: root_path, alert: 'No file provided')
    end

    # Dump a set of scenarios according to the parameters
    def dump
      packer = ScenarioPacker::DumpCollection.from_params(dump_params.to_h, current_user)
      send_data(packer.to_json,
        filename:    packer.filename,
        type:        'application/json',
        disposition: 'attachment')
    rescue ScenarioPacker::DumpCollection::InvalidParamsError => e
      flash[:alert] = e.message
      redirect_back(fallback_location: inspect_scenarios_path)
    end

    private

    def dump_params
      params.permit(:dump_type, :scenario_ids)
    end

    # Returns the uploaded file for scenario loading or raises error if invalid
    def dump_file_param
      params.require(:dump).tap do |f|
        raise ArgumentError, 'No file provided' unless f.respond_to?(:path)
      end
    end

    # Finds and sets the current scenario for edit/show/update actions
    def find_scenario
      @scenario = if params[:id] == 'current'
        @api_scenario
      else
        Scenario::Editable.new(Scenario.find(params[:id]))
      end
    end

    # Extracts strong params for scenario attributes (excluding sortables)
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

    # Extracts strong params for sortable order attributes
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

    # Adds the API scenario ID to URL options if loading a dump
    def default_url_options
      opts = super
      if action_name == 'load_dump' && @api_scenario
        opts.merge(api_scenario_id: @api_scenario.id)
      else
        opts
      end
    end

    # Parses editable attributes from params and assigns them to @scenario
    # Returns false and sets flash alert if parsing fails, true otherwise
    def parse_editable_attributes(redirect_path)
      scenario_attrs = params[:scenario] || {}
      @scenario.user_values = scenario_attrs[:user_values] if scenario_attrs.key?(:user_values)
      @scenario.balanced_values = scenario_attrs[:balanced_values] if scenario_attrs.key?(:balanced_values)
      @scenario.metadata = scenario_attrs[:metadata] if scenario_attrs.key?(:metadata)

      # Check for parsing errors
      if @scenario.errors.any?
        error_list = @scenario.errors.full_messages.map { |msg| "• #{msg}" }.join("<br>")
        flash[:alert] = "Parse errors:<br>#{error_list}".html_safe
        return false
      end

      true
    end

    # Applies scenario changes via orchestrator and updates user sortables in a transaction
    def apply_scenario_changes(scenario, success_path:, failure_path:, success_notice:, render_on_invalid:)
      orchestrator_params = convert_editable_params_to_orchestrator_format(params)
      orchestrator = ::ScenarioUpdater.new(scenario, orchestrator_params, current_user)
      success = false

      Scenario.transaction do
        unless orchestrator.apply
          error_list = orchestrator.errors.full_messages.map { |msg| "• #{msg}" }.join("<br>")
          flash[:alert] = "Validation errors:<br>#{error_list}".html_safe
          raise ActiveRecord::Rollback
        end

        # Build hash of user sortables based on what's available
        sortables = {
          forecast_storage_order: scenario.forecast_storage_order,
          heat_network_order_ht: scenario.heat_network_order(:ht),
          heat_network_order_mt: scenario.heat_network_order(:mt),
          heat_network_order_lt: scenario.heat_network_order(:lt),
          households_space_heating_producer_order: scenario.households_space_heating_producer_order
        }

        # Add hydrogen orders if scenario supports them (present in create but not update)
        if scenario.respond_to?(:hydrogen_supply_order)
          sortables[:hydrogen_supply_order] = scenario.hydrogen_supply_order
          sortables[:hydrogen_demand_order] = scenario.hydrogen_demand_order
        end

        update_user_sortables!(user_sortable_attributes, sortables)
        success = true
      end

      if success
        redirect_to success_path, notice: success_notice
      else
        redirect_to failure_path
      end
    rescue ActiveRecord::RecordInvalid
      render render_on_invalid, status: :unprocessable_entity
    end

    # Updates user sortables with new order values and persists them
    def update_user_sortables!(attrs, records)
      records = records.select { |key, _| attrs.key?(key) }

      records.each do |key, record|
        # Assign the sortable to the scenario explicitly, so we can preserve the object (and errors)
        record.scenario.public_send("#{key}=", record) if record.scenario.respond_to?("#{key}=")
        record.order = attrs[key][:order].to_s.split
      end

      # Validate all records and raise if any are invalid
      raise ActiveRecord::RecordInvalid unless records.all? { |_, rec| rec.valid? }

      # Persist or destroy records depending on whether they’re default
      records.each do |_, record|
        if record.default?
          record.destroy unless record.new_record?
        else
          record.save!(validate: false)
        end
      end
    end

    # Converts form parameters to orchestrator format
    def convert_editable_params_to_orchestrator_format(params)
      orchestrator_params = { scenario: {} }
      scenario_attrs = params[:scenario] || {}

      # Get the underlying scenario (unwrap from Editable wrapper)
      underlying_scenario = @scenario.__getobj__

      # Extract parsed values from the underlying scenario
      %i[user_values balanced_values metadata].each do |attr|
        orchestrator_params[:scenario][attr] = underlying_scenario.public_send(attr) if scenario_attrs.key?(attr)
      end

      # Handle special case attributes
      orchestrator_params[:scenario][:keep_compatible] = scenario_attrs[:keep_compatible] if scenario_attrs.key?(:keep_compatible)
      orchestrator_params[:scenario][:active_couplings] = scenario_attrs[:active_couplings].to_s.split if scenario_attrs.key?(:active_couplings)

      orchestrator_params
    end
  end
end
