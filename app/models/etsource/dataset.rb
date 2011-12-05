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
      unless Rails.env.test? && File.exists?(country_file(country, 'export'))
        # don't check for
        raise "Trying to load a dataset with region code '#{country}' but it does not exist in ETsource."
      end
      
      yml = YAML::load(File.read(country_file(country, 'export')))
      dataset = Qernel::Dataset.new(Hashpipe.hash(country))

      yml.each do |key,attributes|
        key = key.to_s.gsub(/\s/, '')
        key_hashed = Hashpipe.hash(key)

        group = if key.include?('-->')  then :link
                elsif key.include?('(') then :slot
                end
        group ||= :converter

        attrs = {}; attributes.each{|k,v| attrs[k.to_sym] = v}
        dataset.<<(group, key_hashed => attrs)
      end
      dataset.<<(:area, YAML::load(File.read(country_file(country, 'area'))))
      dataset.<<(:carrier, YAML::load(File.read(country_file(country, 'carriers'))))
      dataset.time_curves = YAML::load(File.read(country_file(country, 'time_curves')))
      dataset.data[:graph][:graph][:calculated] = false
      dataset
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
    def country_file(country, file_name)
      "#{base_dir}/#{country}/#{file_name}.yml"
    end
 
  end
end