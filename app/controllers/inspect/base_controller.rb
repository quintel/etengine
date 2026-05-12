# frozen_string_literal: true

class Inspect::BaseController < ApplicationController
  layout 'data'
  before_action :initialize_gql

  authorize_resource :class => false

  rescue_from Inspect::LazyGql::DatasetNotFoundError, with: :handle_missing_dataset

  def redirect
    redirect_to inspect_root_path(:api_scenario_id => params[:api_scenario_id])
  end

  protected

  def initialize_gql
    # Allows the substitution of a "_" in place of a scenario ID if the user
    # wishes to start a new scenario.
    start_scenario_and_redirect && return if params[:api_scenario_id] == '_'

    @api_scenario = Scenario.find_for_calculation(params[:api_scenario_id])
    @gql = Inspect::LazyGql.new(@api_scenario)
  rescue Atlas::DocumentNotFoundError => e
    raise e unless e.message.match?(/could not find a dataset with the key/i)

    start_scenario_and_redirect
  end

  # Starts a new scenario and redirects the user to their requested page for the
  # scenario.
  def start_scenario_and_redirect
    scenario = Scenario.create(
      Scenario.default_attributes.merge(source: 'ETEngine Admin UI')
    )

    redirect_to url_for(api_scenario_id: scenario.id)
  end

  # Handles scenarios with missing/unsupported datasets by redirecting to a new scenario
  def handle_missing_dataset(exception)
    Rails.logger.info(
      "Scenario #{@api_scenario&.id} uses unsupported dataset '#{@api_scenario&.area_code}': #{exception.message}"
    )

    flash[:error] = "This scenario uses an unsupported dataset (#{@api_scenario&.area_code}). Please create a new scenario."
    redirect_to inspect_root_path(api_scenario_id: '_')
  end
end
