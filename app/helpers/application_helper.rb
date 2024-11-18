module ApplicationHelper
  def gravatar_image_tag(address, size: 64, class_name: '')
    default = Rails.env.development? ? 'identicon' : asset_url('quintel-avatar.png')

    image_tag(
      "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(address.downcase)}" \
        "?size=#{size.to_i}&default=#{default}",
      class: class_name
    )
  end

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
    str = str.gsub(/(\(\s*)(#{node_groups(@gql.present.graph).join('|')})(\s*\))/, '\1<span class="gql_group_key">\2</span>\3')

    "<code>#{ str }</code>".html_safe
  end

  def safe_inspect_path
    params[:api_scenario_id] ? inspect_root_path : inspect_path
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

  def notice_message
    if notice.is_a?(Hash)
      notice[:message] || notice['message']
    else
      notice
    end
  end

  def alert_message
    if alert.is_a?(Hash)
      alert[:message] || alert['message']
    else
      alert
    end
  end

  # Like simple_format, except without inserting breaks on newlines.
  def format_paragraphs(text)
    # rubocop:disable Rails/OutputSafety
    text.split("\n\n").map { |content| content_tag(:p, sanitize(content)) }.join.html_safe
    # rubocop:enable Rails/OutputSafety
  end

  # Formats a staff config excerpt for the given application.
  def format_staff_config(config, app)
    format(config, app.attributes.symbolize_keys.merge(
      etengine_url: root_url.chomp('/'),
      etmodel_url: Settings.etmodel_uri || 'http://YOUR_ETMODEL_URL'
    ))
  end

  def format_staff_run_command(command, app)
    format(command, port: app.uri ? URI.parse(app.uri).port : nil)
  end

end
