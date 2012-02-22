class Data::PagesController < Data::BaseController
  def index
    @cache_stats = Rails.cache.stats
  end

  def restart
    Rails.cache.clear
    system("kill -s USR2 `cat #{Rails.root}/tmp/pids/unicorn.pid`") rescue nil
    redirect_to data_root_path(:api_scenario_id => params[:api_scenario_id])
  end

  def clear_cache
    Rails.cache.clear
    redirect_to data_root_path(:api_scenario_id => params[:api_scenario_id])
  end
end
