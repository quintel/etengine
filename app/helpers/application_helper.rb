module ApplicationHelper
  def format_result(result, indent = 0)
    lead  = '  ' * indent

    if result.is_a?(Array)
      lines =
        result.map.with_index do |el, index|
          "#{format_result(el, indent + 1)}," \
          "<span class='suffix'>#{index}</span>"
        end

      return "#{lead}[\n#{lines.join("\n")}\n#{lead}]".html_safe
    end

    line = case result
    when Numeric
      "<span class='mi'>#{ h(number_with_delimiter(result)) }</span>"
    when String
      "<span class='s2'>#{ h(result.inspect) }</span>"
    when Symbol
      "<span class='ss'>#{ h(result.inspect) }</span>"
    else
      "<span class='nb'>#{ h(result.inspect) }</span>"
    end

    "#{ lead }#{ line }".html_safe
  end

  def color_syntaxed_gquery(q)
    str = q
    str = str.gsub(/([A-Z]+)/, '<span class="gql_operator">\1</span>')

    str = str.gsub(/(\()/, '<span class="gql_statement">\1')
    str = str.gsub(/(\))/, '\1</span>')

    str = str.gsub(/(\(\s*)(#{Gquery.cached_keys.join('|')})(\s*\))/, '\1<a class="gql_gquery_key" href="'+inspect_gqueries_path+'/\2">\2</a>\3')
    str = str.gsub(/(\(\s*)(#{converter_groups.join('|')})(\s*\))/, '\1<span class="gql_group_key">\2</span>\3')

    "<code>#{ str }</code>".html_safe
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
end
