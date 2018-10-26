class Data::BaseController < ApplicationController
  layout 'data'
  before_action :initialize_gql

  authorize_resource :class => false

  def redirect
    redirect_to data_root_path(:api_scenario_id => params[:api_scenario_id])
  end

  protected

  def initialize_gql
    api_scenario_id = params[:api_scenario_id] ||= 'latest'

    if api_scenario_id == 'latest'
      @api_scenario = Scenario.last
    else
      @api_scenario = Scenario.find(params[:api_scenario_id])
    end
    @gql = @api_scenario.gql(prepare: true)
  rescue Atlas::DocumentNotFoundError => ex
    if ex.message.match(/could not find a dataset with the key/i)
      scenario = Scenario.create(
        Scenario.default_attributes.merge(source: 'ETEngine Admin UI'))

      redirect_to "/data/#{ scenario.id }"
    else
      raise ex
    end
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
