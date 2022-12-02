class PagesController < ApplicationController
  def index
    return redirect_to(identity_profile_path) if current_user && !current_user.admin?

    scenario = Scenario.default(source: 'ETEngine Admin UI')
    scenario.save!

    redirect_to inspect_root_path(api_scenario_id: scenario.id)
  end
end
