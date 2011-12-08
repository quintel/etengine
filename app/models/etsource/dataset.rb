module Etsource
  class Dataset
    def initialize(etsource = Etsource::Base.new)
      @etsource = etsource
      @datasets = {}
    end

    # Importing dataset and convert into the Qernel::Dataset format.
    # The yml file is a flat (no nested key => values) hash. We move it to a nested hash
    # and also have to convert the keys into a numeric using a hashing function (FNV 1a),
    # the additional nesting of the hash, and hashing ids as strings are mostly for 
    # performance reasons.
    # 
    def import(country = 'nl')
      if !Rails.env.test? && !File.exists?(country_dir(country))
        # don't check for
        raise "Trying to load a dataset with region code '#{country}' but it does not exist in ETsource."
      end
      @input_tool = InputTool::ValueBox.area(country)
      
      dataset = Qernel::Dataset.new(Hashpipe.hash(country))
      
      topology_dataset_files = Dir.glob(country_dir("{#{country},_defaults}")+"/graph/*.yml")
      
      topology_dataset_files.each do |file|
        yml_hsh = load_yaml_with_defaults(country, 'graph/'+file.split("/").last) || {}
        yml_hsh.delete(:defaults)
        yml_hsh.delete(:globals)
        yml_hsh.each do |key,attributes|
          key = key.to_s.gsub(/\s/, '')
          key_hashed = Hashpipe.hash(key)

          group = if key.include?('-->')  then :link
                  elsif key.include?('(') then :slot
                  end
          group ||= :converter

          attrs = {}; attributes.each{|k,v| attrs[k.to_sym] = v}
          dataset.<<(group, key_hashed => attrs)
        end
      end

      dataset.<<(:area,     load_yaml_with_defaults(country, 'area')[:area])
      dataset.<<(:carrier,  load_yaml_with_defaults(country, 'carriers')[:carriers])
      dataset.time_curves = load_yaml(country, 'time_curves')
      dataset.data[:graph][:graph][:calculated] = false
      dataset
    end
    


    def load_yaml_with_defaults(country, file)
      default = File.exists?(country_file('_defaults', file)) ? File.read(country_file('_defaults', file)) : ""
      country = File.exists?(country_file(country, file)) ? File.read(country_file(country, file)) : ""
      content = [default, country].join("\n")
      load_yaml_content(content)
    end

    def load_yaml_content(str)
      YAML::load(ERB.new(str).result(@input_tool.get_binding))
    end

    def load_yaml_file(file_path)
      load_yaml_content(File.read(file_path))
    end

    def load_yaml(country, file)
      load_yaml_content(File.read(country_file(country, file)))
    end

    def export(countries)
      countries.each{|c| export_country(c)}
    end

    def export_country(country = 'nl')
      gql = Gql::Gql.new(::Graph.latest_from_country(country))
      
      FileUtils.mkdir_p base_dir+"/"+country
      graph = gql.future_graph   
      # Assign datasets w/o calculating. Use future graph (present is precalculated).
      graph.dataset = gql.dataset_clone

      # ---- Export Time Curves -----------------------------------------------
      
      File.open(country_file(country, 'time_curves'), 'w') do |out|
        out << YAML::dump(graph.dataset.time_curves)
      end

      # ---- Export Carriers --------------------------------------------------

      File.open(country_file(country, 'carriers'), 'w') do |out|
        hsh = graph.carriers.inject({}) do |hsh, c|
          hsh.merge c.topology_key => c.object_dataset.merge(infinite: c.infinite)
        end
        out << YAML::dump(hsh)
      end

      # ---- Export Area ------------------------------------------------------

      File.open(country_file(country, 'area'), 'w') do |out|
        out << YAML::dump(graph.dataset.data[:area])
      end

      # ---- Export Graph Structure -------------------------------------------

      File.open(country_file(country, 'export'), 'w') do |out|
        out << '---' # Fake YAML format
        graph.converters.each do |converter|
          # Remove the "" from the keys, to make the file look prettier. 
          #     "KEY": { values } => KEY: { values }
          yml = YAML::dump({converter.topology_key => converter.object_dataset}) 
          yml = yml.gsub(/^\"/,'').gsub('":',':').gsub('---','')
          
          out << yml

          converter.outputs.each do |slot|
            attrs = slot.object_dataset.map{|k,v| "#{k}: #{v.inspect}"}.join(', ')
            out << "#{slot.topology_key}: {#{attrs}}\n"
          end

          converter.inputs.each do |slot|
            attrs = slot.object_dataset.map{|k,v| "#{k}: #{v.inspect}"}.join(', ')
            out << "#{slot.topology_key}: {#{attrs}}\n"
            # only export links of inputs, so we don't export them twice.
            slot.links.each do |link|
              attrs = link.object_dataset.map{|k,v| "#{k}: #{v.inspect}"}.join(', ')
              out << "#{link.topology_key}: {#{attrs}}\n"
            end
          end
        end
      end
    end

  #########
  protected
  #########

    def base_dir
      "#{@etsource.base_dir}/datasets"
    end

    # @param [String] country shortcut 'de', 'nl', etc
    #
    def country_dir(country)
      "#{base_dir}/#{country}"
    end
 
    # @param [String] country shortcut 'de', 'nl', etc
    #
    def country_file(country, file_name)
      f = "#{base_dir}/#{country}/#{file_name}"
      f += ".yml" unless f.include?('.yml')
      f
    end
 
  end
end