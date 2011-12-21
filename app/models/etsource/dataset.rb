module Etsource
  class Dataset
    def initialize(etsource = Etsource::Base.new)
      @etsource = etsource
    end

    def import!
    end

    # @return [Hash] {'nl' => {Qernel::Dataset}}
    #
    def import
      countries = Dir.entries(base_dir).select{|dir| (dir =~ /\w+/) && File.directory?("#{base_dir}/#{dir}")}
      countries.inject({}) do |hsh, dir|
        hsh.merge dir => import_country(dir)
      end
    end

    # Importing dataset and convert into the Qernel::Dataset format.
    # The yml file is a flat (no nested key => values) hash. We move it to a nested hash
    # and also have to convert the keys into a numeric using a hashing function (FNV 1a),
    # the additional nesting of the hash, and hashing ids as strings are mostly for 
    # performance reasons.
    # 
    def import_country(country = 'nl')
      fnv = FNV.new # Hashing method
      
      yml = YAML::load(File.read(country_dir(country)))
      dataset = Qernel::Dataset.new(fnv.fnv1a_32(country))

      yml.each do |key,attributes|
        key = key.to_s
        key_hashed = fnv.fnv1a_32(key)
        group = if key.include?('-- ')  then :link
                elsif key.include?('(') then :slot
                else :converter
                end
        dataset.<<(group, key_hashed => attributes)
      end

      dataset
    end
    
    def all_countries
      Area.all.map(&:region_code)
    end

    def export
      all_countries.each{|c| export_country(c)}
    end

    def export_country(country = 'nl')
      # EDGE/Staging conflict/diverge:
      # In staging branch we still load gql from the database.
      # In Edge the way we load/initialize Gql changes. Ovewrwrite
      # with code from Edge branch.
      graph_model = ::Graph.latest_from_country(country)
      future_dataset = graph_model.dataset.to_qernel
      gql = Gql::Gql.new(graph_model)
      
      
      FileUtils.mkdir_p base_dir+"/"+country # +"/graph"
      
      graph = gql.future_graph   
      # Assign datasets w/o calculating. Use future graph (present is precalculated).
      graph.dataset = future_dataset

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
        #out << YAML::dump({:area => graph.dataset.data[:area]})
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
 
  protected
    
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