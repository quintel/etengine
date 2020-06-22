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
    haml_tag :h3, "UPDATE commands"
    if tree = Qernel::Logger.to_tree(updates)
      log_subtree(tree)
    end
  end

  def log_subtree(subtree)
    if @gquery_keys.nil? || @method_definitions.nil?
      raise "log_subtree requires the variables @gquery_keys and @method_definitions"
    end

    haml_tag 'ul.unstyled' do
      subtree.each do |parent, children|
        next if parent.nil?
        haml_tag :li do
          type      = parent[:type]
          attr_name = parent[:attr_name]
          value     = parent[:value]


          haml_tag :p, :class => type do
            haml_tag "span.label.unfold_toggle", type.to_s, :class => LABELS[type]
            haml_concat "&nbsp;"

            log_folding_tags(type)
            log_title(parent)
            log_value(value)
          end

          if (gquery_key = parent[:gquery_key]) && !@gquery_keys.include?(gquery_key)
            if gquery =  Gquery.get(gquery_key.to_s)
              haml_tag 'strong.pull-right', (gquery.unit || '-')+" "
              haml_tag 'div.offset1' do
                with_tabs(0) do
                  haml_tag :pre, gquery.query, :class => 'gql'
                end
              end
              @gquery_keys << gquery_key
            end
          end

          log_subtree(children) unless children.nil?
        end
      end
    end
  end

  def log_title(log)
    type      = log[:type]
    attr_name = log[:attr_name]
    value     = log[:value]
    if type == :method
      haml_tag 'a.attr_name', attr_name.to_s,
        :rel  => 'modal',
        :href => 'javacsript:void(null)',
        :data => {
          :target        => "##{attr_name}",
          :"toggle" => :modal
        }
      @method_definitions << attr_name
    else
      haml_tag 'span.attr_name', attr_name.to_s
      if log[:node]
        haml_concat link_to(">>", inspect_node_path(:id => log[:node]))
      end
    end
  end

  def log_value(value)
    value = value.first if value.is_a?(Array) and value.length == 1

    if value.is_a?(Array)
      haml_tag 'strong.pull-right', "#{value.length} #"
    else
      haml_tag 'strong.pull-right', auto_number(value)
    end
  end

  def log_folding_tags(type)
    return
    haml_tag 'span' do
      if type == :attr
        haml_tag 'span', '-'
        haml_tag 'span', '+'
      else
        haml_tag 'a.fold_all',   '-', :href => 'javascript:void(null)'
        haml_tag 'a.unfold_all', '+', :href => 'javascript:void(null)'
      end
      # haml_tag 'a.unfold_1', '1', :href => '#'
      # haml_tag 'a.unfold_2', '2', :href => '#'
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
