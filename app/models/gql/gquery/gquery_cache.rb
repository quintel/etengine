module Gql
##
# GqueryCache caches #query and #subquery calls on the present graph using Rails.cache.
#
module Gquery::GqueryCache

  ##
  # DANGEEROURS. What happens if Converter objects are returned???
  #
  def subquery(gquery_key)
    if scope.graph.present? and gquery = ::Gquery.get(gquery_key) and !gquery.not_cacheable?
      val = Rails.cache.fetch("/gquery_cache/#{scope.dataset_id}/#{gquery.key}/#{gquery.updated_at}") do
        # BUG/DEBT memcached seems to be unable to store false values
        val = super(gquery_key)
        val === false ? :false : val
      end
      val === :false ? false : val
    else
      super(gquery_key)
    end
  end
end

end
