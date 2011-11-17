module Etsource
  class Dataset
    def initialize(etsource = Etsource::Base.new)
      @etsource = etsource
    end

    def dataset(country)
      @datasets ||= import
      @datasets[country.to_sym]
    end

    # @return [Hash] {'nl' => {Qernel::Dataset}}
    #
    def import
      countries = Dir.entries(base_dir).select{|dir| (dir =~ /\w+/) && File.directory?("#{base_dir}/#{dir}")}
      countries.inject({}) do |hsh, dir|
        hsh.merge dir.to_sym => import_country(dir)
      end
    end

    # Importing dataset and convert into the Qernel::Dataset format.
    # The yml file is a flat (no nested key => values) hash. We move it to a nested hash
    # and also have to convert the keys into a numeric using a hashing function (FNV 1a),
    # the additional nesting of the hash, and hashing ids as strings are mostly for 
    # performance reasons.
    # 
    def import_country(country = 'nl')
      yml = YAML::load(File.read(country_file(country)))
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
      dataset.<<(:area, :area_data => {})
      dataset
    end
    
    def export(countries)
      countries.each{|c| export_country(c)}
    end

    def export_country(country = 'nl')
      gql = Gql::Gql.load(country)
      
      FileUtils.mkdir_p base_dir+"/"+country
      
      File.open(country_file(country), 'w') do |out|
        out << '---'
        
        # Assign datasets w/o calculating. Use future graph (present is precalculated).
        graph = gql.tap(&:assign_dataset).future_graph
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
    def country_file(country)
      "#{base_dir}/#{country}/export.yml"
    end
 
  end
end