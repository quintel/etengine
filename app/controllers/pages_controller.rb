class PagesController < ApplicationController
  before_action :ensure_user, only: [:index]

  def index
    return redirect_to(sign_in_path) unless current_user.admin?

    scenario = Scenario.default(source: 'ETEngine Admin UI')
    scenario.save!

    redirect_to inspect_root_path(api_scenario_id: scenario.id)
  end

  private

  def ensure_user
    redirect_to sign_in_path unless current_user
  end
end
