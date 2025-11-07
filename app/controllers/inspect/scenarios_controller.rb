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

      process_scenario_save(
        scenario: scenario,
        edit_path: new_inspect_scenario_path,
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
      underlying_scenario = @scenario.__getobj__

      process_scenario_save(
        scenario: underlying_scenario,
        edit_path: edit_inspect_scenario_path(id: underlying_scenario.id),
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

    # Coordinates parsing and saving of scenario with sortables
    def process_scenario_save(scenario:, edit_path:, success_notice:, render_on_invalid:)
      return redirect_to edit_path unless assign_parsed_attributes(edit_path)

      apply_scenario_changes(
        scenario,
        success_path: inspect_scenario_path(id: scenario.id),
        failure_path: edit_path,
        success_notice: success_notice,
        render_on_invalid: render_on_invalid
      )
    end

    # Assigns parsed editable attributes from params to @scenario
    # Returns false and sets flash alert if parsing fails, true otherwise
    def assign_parsed_attributes(redirect_path)
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

    # Applies scenario changes via updater and updates user sortables in a transaction
    def apply_scenario_changes(scenario, success_path:, failure_path:, success_notice:, render_on_invalid:)
      updater_params = build_updater_params(params)
      force_update = params[:force_update].present?
      result = ::ScenarioUpdater.new(scenario, updater_params, current_user, skip_validation: force_update).call
      success = false
      sortable_attrs = user_sortable_attributes
      sortable_records = build_sortables_hash(scenario)

      Scenario.transaction do
        prepared_sortables, sortable_errors = prepare_sortables(sortable_records, sortable_attrs, force_update: force_update)
        formatted_sortable_errors = format_sortable_errors(sortable_errors)

        if result.failure?
          combined_errors = Array(result.failure) + formatted_sortable_errors
          handle_updater_failure(combined_errors, force_update)
          raise ActiveRecord::Rollback
        end

        if sortable_errors.any?
          handle_updater_failure(formatted_sortable_errors, force_update)
          raise ActiveRecord::Rollback
        end

        persist_sortables!(prepared_sortables)
        success = true
      end

      if success
        redirect_to success_path, notice: success_notice
      else
        # If there are validation errors and force_update wasn't used, render the form
        if flash.now[:show_force_update]
          render render_on_invalid, status: :unprocessable_entity
        else
          redirect_to failure_path
        end
      end
    rescue ActiveRecord::RecordInvalid
      render render_on_invalid, status: :unprocessable_entity
    end

    # Builds hash of sortable associations for a scenario
    def build_sortables_hash(scenario)
      sortables = {
        forecast_storage_order: scenario.forecast_storage_order,
        heat_network_order_ht: scenario.heat_network_order(:ht),
        heat_network_order_mt: scenario.heat_network_order(:mt),
        heat_network_order_lt: scenario.heat_network_order(:lt),
        households_space_heating_producer_order: scenario.households_space_heating_producer_order
      }

      # Add hydrogen orders if scenario supports them
      if scenario.respond_to?(:hydrogen_supply_order)
        sortables[:hydrogen_supply_order] = scenario.hydrogen_supply_order
        sortables[:hydrogen_demand_order] = scenario.hydrogen_demand_order
      end

      sortables
    end

    # Applies user input to sortable records, returning the mutated records and any validation errors
    def prepare_sortables(records, attrs, force_update:)
      selected_records = {}
      errors = {}

      records.each do |key, record|
        attributes = attrs[key] || attrs[key.to_s]
        next unless attributes

        selected_records[key] = record

        # Assign the sortable to the scenario explicitly, so we can preserve the object (and errors)
        record.scenario.public_send("#{key}=", record) if record.scenario.respond_to?("#{key}=")
        record.order = attributes[:order].to_s.split

        next if record.valid?

        if force_update
          record.order = record.useable_order
          record.errors.clear
        else
          errors[key] = record.errors.full_messages
        end
      end

      [selected_records, errors]
    end

    # Persists user sortables with new order values
    def persist_sortables!(records)
      records.each do |_, record|
        if record.default?
          record.destroy unless record.new_record?
        else
          record.save!(validate: false)
        end
      end
    end

    SORTABLE_LABELS = {
      forecast_storage_order: 'Forecast storage order',
      hydrogen_supply_order: 'Hydrogen producer order',
      hydrogen_demand_order: 'Hydrogen flex demand order',
      heat_network_order_ht: 'Heat network (HT) dispatchables order',
      heat_network_order_mt: 'Heat network (MT) dispatchables order',
      heat_network_order_lt: 'Heat network (LT) dispatchables order',
      households_space_heating_producer_order: 'Households space heating producer order'
    }.freeze
    private_constant :SORTABLE_LABELS

    def format_sortable_errors(errors)
      errors.flat_map do |key, messages|
        label = SORTABLE_LABELS[key] || key.to_s.humanize
        Array(messages).compact.map { |message| "#{label}: #{message}" }
      end
    end

    # Handles updater validation failures by setting flash messages and preserving form input
    def handle_updater_failure(errors, force_update)
      error_array = Array(errors).flatten
      # Store errors for display in the view
      flash.now[:validation_errors] = error_array

      # Preserve raw form inputs for re-rendering (prevents YAML->JSON conversion)
      scenario_params = params[:scenario] || {}
      @raw_user_values = scenario_params[:user_values] if scenario_params.key?(:user_values)
      @raw_balanced_values = scenario_params[:balanced_values] if scenario_params.key?(:balanced_values)
      @raw_metadata = scenario_params[:metadata] if scenario_params.key?(:metadata)

      # If force_update is not set, give user option to force the update
      if !force_update
        flash.now[:show_force_update] = error_array.present?
      elsif error_array.present?
        # If force_update was set but still failed, show error without force option
        error_list = error_array.map { |msg| "• #{msg}" }.join("<br>")
        flash.now[:alert] = "Failed to update:<br>#{error_list}".html_safe
      end
    end

    # Builds updater parameters from form input
    def build_updater_params(params)
      updater_params = { scenario: {} }
      scenario_attrs = params[:scenario] || {}

      # Get the underlying scenario (unwrap from Editable wrapper)
      underlying_scenario = @scenario.__getobj__

      # Extract parsed values from the underlying scenario
      %i[user_values balanced_values metadata].each do |attr|
        updater_params[:scenario][attr] = underlying_scenario.public_send(attr) if scenario_attrs.key?(attr)
      end

      # Handle special case attributes
      updater_params[:scenario][:keep_compatible] = scenario_attrs[:keep_compatible] if scenario_attrs.key?(:keep_compatible)
      updater_params[:scenario][:active_couplings] = scenario_attrs[:active_couplings].to_s.split if scenario_attrs.key?(:active_couplings)

      updater_params
    end
  end
end
