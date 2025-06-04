# frozen_string_literal: true

module Inspect
  class ScenariosController < Inspect::BaseController
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

    # Shows a single scenario
    def show
      respond_to(&:html)
    end

    # Renders form for editing an existing scenario
    def edit; end

    # Updates a scenario and its user sortables
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

    # GET /inspect/scenarios/dump?scenario_ids=1,2,3
    def dump
      ids = parsed_scenario_ids
      if ids.empty?
        flash[:alert] = 'Please enter at least one scenario ID.'
        return redirect_back(fallback_location: inspect_scenarios_path)
      end

      packer = ScenarioPacker::DumpCollection.new(ids)
      send_data(packer.to_json,
                filename: packer.filename,
                type: 'application/json',
                disposition: 'attachment')
    end

    private

    def dump_params
      params.permit(:scenario_ids, :commit)
    end

    # Returns the uploaded file for scenario loading or raises error if invalid
    def dump_file_param
      params.require(:dump).tap do |f|
        raise ArgumentError, 'No file provided' unless f.respond_to?(:path)
      end
    end

    # Parses params[:scenario_ids], sets a flash + redirect if empty,
    # and returns a (possibly empty) Array of Integer IDs.
    def parsed_scenario_ids
      raw = params[:scenario_ids].to_s
      raw
        .split(/\s*,\s*/)
        .map(&:to_i)
        .reject(&:zero?)
        .uniq
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

    # Updates user sortables with new order values and persists them
    def update_user_sortables!(attrs, records)
      records = records.select { |key, _| attrs.key?(key) }

      records.each do |key, record|
        # Assign the sortable to the scenario explicitly, so we can preserve the object (and errors)
        record.scenario.public_send("#{key}=", record) if record.scenario.respond_to?("#{key}=")
        record.order = attrs[key][:order].to_s.split
      end

      # Validate all records and raise if any are invalid
      unless records.reduce(true) { |status, (_, rec)| rec.valid? && status }
        raise ActiveRecord::RecordInvalid
      end

      # Persist or destroy records depending on whether they’re default
      records.each do |_, record|
        if record.default?
          record.destroy unless record.new_record?
        else
          record.save!(validate: false)
        end
      end
    end
  end
end
