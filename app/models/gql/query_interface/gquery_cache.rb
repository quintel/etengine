module Gql

# GqueryCache caches #query and #subquery calls on the present graph using Rails.cache.
#
module QueryInterface::GqueryCache

  ##
  # DANGEEROURS. What happens if Converter objects are returned???
  #
  def subquery(gquery_key)
    gquery = get_gquery(gquery_key)

    if graph.present? and gquery and gquery.cacheable?
      val = Rails.cache.fetch("/gquery_cache/#{dataset_id}/#{gquery.key}/#{gquery.updated_at}") do
        # BUG/DEBT memcached seems to be unable to store false values
        val = super(gquery)
        val === false ? :false : val
      end
      val === :false ? false : val
    else
      super(gquery)
    end
  end
end

end
