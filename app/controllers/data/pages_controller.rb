class Backend::PagesController < Backend::BaseController
  layout 'application'

  def index
    @cache_stats = Rails.cache.respond_to?(:stats) ? Rails.cache.stats : {}
  end

  def restart
    Rails.cache.clear
    system("kill -s USR2 `cat #{Rails.root}/tmp/pids/unicorn.pid`") rescue nil
    redirect_to backend_root_path(:api_scenario_id => params[:api_scenario_id])
  end

  def clear_cache
    NastyCache.instance.expire!
    redirect_to backend_root_path(:api_scenario_id => params[:api_scenario_id])
  end
end
