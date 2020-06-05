# frozen_string_literal: true

class Inspect::BaseController < ApplicationController
  layout 'data'
  before_action :initialize_gql

  authorize_resource :class => false

  def redirect
    redirect_to inspect_root_path(:api_scenario_id => params[:api_scenario_id])
  end

  protected

  def initialize_gql
    # Allows the substitution of a "_" in place of a scenario ID if the user
    # wishes to start a new scenario.
    start_scenario_and_redirect && return if params[:api_scenario_id] == '_'

    @api_scenario = Scenario.find(params[:api_scenario_id])
    @gql = @api_scenario.gql(prepare: true)
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

  # Internal: Renders a 404 page.
  #
  # thing - An optional noun, describing what thing could not be found. Leave
  #         nil to say "the page cannot be found"
  #
  # For example
  #   render_not_found('scenario') => 'the scenario cannot be found'
  #
  # Returns true.
  def render_not_found(thing = nil)
    content = Rails.root.join('public/404.html').read

    unless thing.nil?
      # Swap out the word "page" for something else, when appropriate.
      document = Nokogiri::HTML.parse(content)
      header = document.at_css('h1')
      header.content = header.content.sub(/\bpage\b/, thing)

      content = document.to_s
    end

    render(
      html: content.html_safe,
      status: :not_found,
      layout: false
    )

    true
  end
end
