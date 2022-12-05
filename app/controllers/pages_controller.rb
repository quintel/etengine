class PagesController < ApplicationController
  before_action :authenticate_user!, only: [:index]

  def index
    return redirect_to(identity_profile_path) unless current_user.admin?

    scenario = Scenario.default(source: 'ETEngine Admin UI')
    scenario.save!

    redirect_to inspect_root_path(api_scenario_id: scenario.id)
  end
end
