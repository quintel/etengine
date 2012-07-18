module DebugHelper
  LABELS = {gql: 'label-info', method: 'label-inverse', set: 'label-warning' }

  def method_source(method_name)
    f, line = Qernel::ConverterApi.instance_method(method_name).andand.source_location
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

  def log_tree(logs = @logs)
    tree = Qernel::Logger.to_tree(logs)
    log_subtree(tree)
  end

  def log_subtree(subtree)
    haml_tag 'ul.unstyled' do
      subtree.each do |parent, children|
        next if parent.nil?
        haml_tag :li do
          type      = parent[:type]
          attr_name = parent[:attr_name]
          value     = parent[:value]


          haml_tag :p, :class => type do
            haml_tag "span.label.unfold_toggle", type.to_s, :class => LABELS[type]
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
            
            if type == :method
              haml_tag 'a.attr_name', attr_name.to_s, 
                :rel  => 'modal', 
                :href => '#',
                :data => {
                  :target        => "##{attr_name}", 
                  :"toggle" => :modal
                }

              @method_definitions << attr_name
            else
              haml_tag 'span.attr_name', attr_name.to_s
            end
            value = value.first if value.is_a?(Array) and value.length == 1
            
            if value.is_a?(Array) 
              haml_tag 'strong.pull-right', "#{value.length} #"
            else
              haml_tag 'strong.pull-right', auto_number(value)
            end
          end

          if parent[:key] == 'Q'
            gquery =  Gquery.get(parent[:attr_name].split(' ').last)
            haml_tag 'strong.pull-right', (gquery.unit || '-')+" "
            with_tabs(0) do
              haml_tag :pre, gquery.query
            end
          end

          log_subtree(children) unless children.nil?
        end
      end
    end
  end


end