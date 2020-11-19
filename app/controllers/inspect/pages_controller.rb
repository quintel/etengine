class Inspect::PagesController < Inspect::BaseController
  layout 'application'
  skip_before_action :initialize_gql, only: :start_inspect

  def index
    @cache_stats = Rails.cache.respond_to?(:stats) ? Rails.cache.stats : {}
  end

  # The user ends up here if they visit /inspect without a scenario ID.
  def start_inspect
    scenario = Scenario.create(Scenario.default_attributes)
    redirect_to inspect_root_path(api_scenario_id: scenario.id)
  end

  def clear_cache
    NastyCache.instance.expire!
    redirect_to inspect_root_path(:api_scenario_id => params[:api_scenario_id])
  end
end
