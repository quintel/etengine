module DebugHelper
  LABELS = {gql: 'label-info', method: 'label-inverse', set: 'label-warning', error: 'label-important' }

  def method_source(method_name)
    Rails.cache.fetch("methods/source/#{method_name}") do
      begin
        f, line = Qernel::NodeApi.instance_method(method_name)&.source_location
        if f and line
          lines = File.read(f).lines.to_a

          source = lines[line - 1]
          intendation = source.match(/^(\s*)def/).captures.first

          lines[line..-1].each do |l|
            if l.match(/^#{intendation}end/)
              source << l
              break
            else
              source << l
            end
          end
          source
        end
      rescue => e
        e
      end
    end
  end

  def log_tree(logs = @logs)
    updates, logs = logs.partition{|l| l[:type] == :update}

    if tree = Qernel::Logger.to_tree(logs)
      log_subtree(tree)
    end
    concat content_tag(:h3, "UPDATE commands")
    if tree = Qernel::Logger.to_tree(updates)
      log_subtree(tree)
    end
  end

  def log_subtree(subtree)
    if @gquery_keys.nil? || @method_definitions.nil?
      raise "log_subtree requires the variables @gquery_keys and @method_definitions"
    end

    concat content_tag('ul', class: 'unstyled') {
      subtree.each do |parent, children|
        next if parent.nil?
        concat content_tag(:li) {
          type      = parent[:type]
          attr_name = parent[:attr_name]
          value     = parent[:value]

          concat content_tag(:p, class: type) {
            concat content_tag("span", type.to_s, class: "label unfold_toggle #{LABELS[type]}")
            concat "&nbsp;".html_safe

            log_folding_tags(type)
            log_title(parent)
            log_value(value)
          }

          if (gquery_key = parent[:gquery_key]) && !@gquery_keys.include?(gquery_key)
            if gquery =  Gquery.get(gquery_key.to_s)
              concat content_tag('strong', (gquery.unit || '-')+" ", class: 'pull-right')
              concat content_tag('div', class: 'offset1') {
                  concat content_tag(:pre, gquery.query, class: 'gql')
              }
              @gquery_keys << gquery_key
            end
          end

          log_subtree(children) unless children.nil?
        }
      end
    }
  end

  def log_title(log)
    type      = log[:type]
    attr_name = log[:attr_name]
    value     = log[:value]
    if type == :method
      concat content_tag('a', attr_name.to_s,
        :rel  => 'modal',
        :href => 'javacsript:void(null)',
        :data => {
          :target        => "##{attr_name}",
          :"toggle" => :modal
        },
        :class => 'attr_name'
      )
      @method_definitions << attr_name
    else
      concat content_tag('span', attr_name.to_s, class: 'attr_name')
      if log[:node]
        concat link_to(">>", inspect_node_path(id: log[:node], graph_name: :energy))
      end
    end
  end

  def log_value(value)
    value = value.first if value.is_a?(Array) and value.length == 1

    if value.is_a?(Array)
      concat content_tag('strong', "#{value.length} #", class: 'pull-right')
    else
      concat content_tag('strong', auto_number(value), class: 'pull-right')
    end
  end

  def log_folding_tags(type)
    return
    concat content_tag('span') do
      if type == :attr
        concat content_tag('span', '-')
        concat content_tag('span', '+')
      else
        concat content_tag('a', '-', href: 'javascript:void(null)', class: 'fold_all')
        concat content_tag('a', '+', href: 'javascript:void(null)', class: 'unfold_all')
      end
      # concat content_tag('a', '1', href: '#', class: 'unfold_1')
      # concat content_tag('a', '2', href: '#', class: 'unfold_2')
    end
  end

  def calculation_debugger_path(node, calculation)
    inspect_debug_gql_path(:gquery => "V(#{node.key}, #{calculation})")
  end

  # Merit Order --------------------------------------------------------------

  def merit_order_nodes(graph, type)
    unless nodes = Etsource::MeritOrder.new.import_electricity[type.to_s]
      raise "No such merit order group: #{ type.inspect }"
    end

    nodes.
      map     { |key, *| graph.node(key) }.
      sort_by { |node| node[:merit_order_position] }
  end
end
