class Data::PagesController < Data::BaseController
  def index
    @cache_stats = Rails.cache.stats
  end
end
