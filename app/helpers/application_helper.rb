module ApplicationHelper
  def clippy(text, bgcolor='#FFFFFF')
    html = <<-EOF
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
              width="110"
              height="14"
              id="clippy" >
      <param name="movie" value="/clippy.swf"/>
      <param name="allowScriptAccess" value="always" />
      <param name="quality" value="high" />
      <param name="scale" value="noscale" />
      <param NAME="FlashVars" value="text=#{h(text)}">
      <param name="bgcolor" value="#{bgcolor}">
      <embed src="/clippy.swf"
             width="110"
             height="14"
             name="clippy"
             quality="high"
             allowScriptAccess="always"
             type="application/x-shockwave-flash"
             pluginspage="http://www.macromedia.com/go/getflashplayer"
             FlashVars="text=#{h(text)}"
             bgcolor="#{bgcolor}"
      />
      </object>
    EOF
    html.html_safe
  end

  def format_result(result, indent = 0)
    lead  = '  ' * indent

    if result.is_a?(Array)
      lines = result.map { |el| format_result(el, indent + 1) }
      return "#{ lead }[\n#{ lines.join(",\n") }\n#{ lead }]"
    elsif result.is_a?(String) && indent.zero?
      # Raw string result (TXT_TABLE, etc).
      return result.lines.map { |line| "#{ lead }#{ line }" }.join("\n")
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

    "#{ lead }#{ line }"
  end

  def color_syntaxed_gquery(q)
    str = q
    str = str.gsub(/([A-Z]+)/, '<span class="gql_operator">\1</span>')

    str = str.gsub(/(\()/, '<span class="gql_statement">\1')
    str = str.gsub(/(\))/, '\1</span>')

    str = str.gsub(/(\(\s*)(#{Gquery.cached_keys.join('|')})(\s*\))/, '\1<a class="gql_gquery_key" href="'+data_gqueries_path+'/\2">\2</a>\3')
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
