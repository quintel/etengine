module Gql

# QueryCache caches #query and #subquery calls on the present graph using Rails.cache.
#
module QueryInterface::QueryCache

  def subquery(gquery_key)
    gquery = get_gquery(gquery_key)

    if options[:cache_prefix] && gquery && gquery.cacheable?
      val = Rails.cache.fetch("/gquery_cache/#{options[:cache_prefix]}/#{gquery.key}") do
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
