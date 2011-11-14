module Etsource
  class Dataset
    def initialize(etsource)
      @etsource = etsource || Etsource::Base.new
    end

    def import!
    end

    def base_dir
      "#{@etsource.base_dir}/datasets"
    end

    # @param [String] country shortcut 'de', 'nl', etc
    #
    def country_dir(country)
      "#{base_dir}/#{country}/export.yml"
    end

<<<<<<< HEAD
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
    
    def export(country = 'nl')
=======
    def import
      country = 'nl'
      yml = YAML::load(File.read(country_dir(country)))
      fnv = FNV.new
      dataset = {}
      yml.each do |k,v|
        dataset[fnv.fnv1a_32(k.to_s)] = v
      end
      dataset
    end
    
    def export
      country = 'nl'
      
>>>>>>> Etsource::Dataset#import / #export
      gql = Gql::Gql.new(::Graph.latest_from_country(country), ::Dataset.latest_from_country(country))
      FileUtils.mkdir_p country_dir(country)
      
      File.open(country_dir(country), 'w') do |out|
        out << '---'
        g = gql.tap(&:assign_dataset).future_graph # the future graph is not calculated.
        g.converters.each do |converter|
          out << YAML::dump({converter.topology_key => converter.object_dataset}).gsub(/^\"/,'').gsub('":',':').gsub('---','')
          converter.outputs.each do |slot|
            out << "#{slot.topology_key}: #{slot.object_dataset.inspect}\n"
          end
          converter.inputs.each do |slot|
            out << "#{slot.topology_key}: #{slot.object_dataset.inspect}\n"
            slot.links.each do |link|
              out << "#{link.topology_key}: #{link.object_dataset.inspect}\n"
            end
          end
        end
      end
    end
    
  end
end