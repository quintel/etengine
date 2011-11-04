class Data::PagesController < Data::BaseController
  def index
    @cache_stats = Rails.cache.stats
  end

  def restart
    Rails.cache.clear
    system("touch tmp/restart.txt")
    redirect_to data_root_path(
      :blueprint_id => params[:blueprint_id],
      :region_code  => params[:region_code])
  end

  def clear_cache
    Rails.cache.clear
    redirect_to data_root_path(
      :blueprint_id => params[:blueprint_id],
      :region_code  => params[:region_code])
  end
end
