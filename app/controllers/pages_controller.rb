class PagesController < ApplicationController
  def index
    scenario = Scenario.default(source: 'ETEngine Admin UI')
    scenario.save!

    redirect_to inspect_root_path(api_scenario_id: scenario.id)
  end
end
