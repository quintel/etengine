module ApplicationHelper
  def color_syntaxed_gquery(q)
    str = q
    str = str.gsub(/([A-Z]+)/, '<span class="gql_operator">\1</span>')

    str = str.gsub(/(\()/, '<span class="gql_statement">\1')
    str = str.gsub(/(\))/, '\1</span>')

    str = str.gsub(/(\(\s*)(#{Gquery.cached_keys.join('|')})(\s*\))/, '\1<a class="gql_gquery_key" href="'+data_gqueries_path+'/key/\2">\2</a>\3')
    str = str.gsub(/(\(\s*)(#{Group.keys.join('|')})(\s*\))/, '\1<span class="gql_group_key">\2</span>\3')
    str.html_safe
  end

  def asset_cache_name(name)
    if Rails.env.development?
      # we set config.perform_caching to true in development (to cache the Graph-qernel)
      # so we have to return false, otherwise changes won't be dodated
      false
    else
      "cache_#{name}"
    end
  end

  def t_db(key)
    begin
      Translation.find_by_key(key).content.html_safe
    rescue
      "translation missing, #{I18n.locale.to_s.split('-').first} #{key}"
    end
  end

  # Used in the admin section to show a warning header
  #
  def live_server?
    APP_CONFIG[:live_server]
  end
end
