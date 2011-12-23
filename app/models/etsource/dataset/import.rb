module Etsource
  # ------ Static vs dynamic form yml  ------------------------------------------
  #
  # The ETsource dataset is split into static and dynamic ymls. The static ones
  # don't rely on others and are loaded first. The dynamic form ymls are loaded
  # after that, so it can access static dataset using #val and research input
  # with #get.
  #
  # ------ Importing ETsource Transformer Files  ---------------------------------
  #
  # To make the ETsource dataset forms dynamic we pass the yml files through an
  # ERB handler, and load the output with YAML::load. 
  # So that the dynamic yml.erb form templates (the suffix .erb is not needed), can
  # access the values of the static datasets and the researchers form input, we 
  # add a binding to the yaml files to this Etsource::Dataset object. So calling 
  # #get within a yml will call Etsource::Dataset#get
  #
  class Dataset::Import
    attr_reader :country
    
    def initialize(country)
      # DEBT: @etsource is only used for the base_dir, can be solved better.
      @etsource = Etsource::Base.new
      @country  = country
      @dataset = Qernel::Dataset.new(Hashpipe.hash(country))
    end

    # Importing dataset and convert into the Qernel::Dataset format.
    # The yml file is a flat (no nested key => values) hash. We move it to a nested hash
    # and also have to convert the keys into a numeric using a hashing function (FNV 1a),
    # the additional nesting of the hash, and hashing ids as strings are mostly for 
    # performance reasons.
    # 
    def import
      if !Rails.env.test? && !File.exists?(country_dir(country))
        # don't check for
        raise "Trying to load a dataset with region code '#{country}' but it does not exist in ETsource."
      end

      load_area
      load_carriers
      load_time_curves
      @dataset.data[:graph][:graph][:calculated] = false

      load_country_dataset
      load_dataset_wizards

      @dataset
    end
   
    # Return all the carrier keys we have defined in the dataset.
    # (used to dynamically generate some methods)
    def carrier_keys
      load_yaml_with_defaults('carriers')[:carriers].keys
    end

  #########
  protected
  #########

    # ---- Import Area ------------------------------------------------------

    def load_area
      @dataset.merge(:area,     load_yaml_with_defaults('area')[:area])
    rescue => e
      raise "Error loading datasets/:country/area.yml: #{e}"
    end

    # ---- Import Carriers --------------------------------------------------

    def load_carriers
      @dataset.merge(:carrier,  load_yaml_with_defaults('carriers')[:carriers])
    rescue =>e
      raise "Error loading datasets/:country/carriers.yml: #{e.inspect}"
    end    

    # ---- Import Time Curves -----------------------------------------------

    def load_time_curves
      @dataset.time_curves = load_yaml('time_curves')
    rescue =>e
      raise "Error loading datasets/:country/time_curves.yml: #{e.inspect}"
    end    

    # ---- Import Static -----------------------------------------------

    def load_country_dataset
      # Topology:
      # Load each file, remove :defaults and :globals from hsh, so we don't mess with the rest.
      # merge with @dataset.
      
      topology_dataset_files = Dir.glob([base_dir, "{#{country},_defaults}", "graph/*.yml"].join('/'))
      topology_dataset_files.each do |file|
        hsh = load_yaml_with_defaults('graph/'+file.split("/").last) || {}
        merge_hash_with_dataset!(hsh)
      end
    rescue => e
      raise "Error loading datasets/:country/graph/*.yml: #{e.inspect}"
    end

    # ---- Import Dynamic with Research Data ----------------------------------

    def load_dataset_wizards
      research_dataset = InputTool::ResearchDataset.area(country)
      # Import dynamic dataset (can reliably lookup information of static dataset)
      # This allows to lookup values from the static dataset
      Dir.glob([base_dir, '_wizards', '*', "transformer.yml"].join('/')).each do |file|
        hsh = ::Etsource::Dataset::Renderer.new(file, research_dataset, @dataset).result
        merge_hash_with_dataset!(hsh)
      end
    end
 
    def merge_hash_with_dataset!(hsh)
      # Dont make converters with keys :defaults and :globals 
      hsh.delete(:defaults) 
      hsh.delete(:globals)

      hsh.each do |key,attributes|
        if key == :area
          # area is a special kid for now. dont hash keys or groups
          @dataset.merge(key, attributes)  
        else
          attrs = {}; attributes.each{|k,v| attrs[k.to_sym] = v}
          @dataset.merge(group_key(key), Hashpipe.hash(key) => attrs)
        end
      end
    end

  protected
    
    # Messy legacy hack. Have no words for it right now.
    def group_key(key)
      key = key.to_s
      if key.include?('-->')  then :link
      elsif key.include?('(') then :slot
      else                         :converter; end
    end

    # If there is a corresponding file in _defaults (has the same name), prepend
    # the _defaults file to the actual, so that we can work with << &default_attrs
    # This is solely needed to make << &foo_bar work, otherwise we could just as
    # well only load the default file first.
    #
    def load_yaml_with_defaults(file)
      default_data = File.exists?(country_file('_defaults', file)) ? File.read(country_file('_defaults', file)) : ""
      country_data = File.exists?(country_file(country, file)) ? File.read(country_file(country, file)) : ""
      content = [default_data, country_data].join("\n")
      load_yaml_content(content)
    end

    def load_yaml_content(str)
      YAML::load(ERB.new(str).result(binding))
    end

    def load_yaml_file(file_path)
      load_yaml_content(File.read(file_path))
    end

    def load_yaml(file)
      load_yaml_file(country_file(country, file))
    end

    def base_dir
      "#{@etsource.base_dir}/datasets"
    end

    # @param [String] country shortcut 'de', 'nl', etc
    #
    def country_dir(c = country)
      "#{base_dir}/#{c}"
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

