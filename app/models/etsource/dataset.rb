# ------ Binding to ETsource template -----------------------------------------
#
# A ETsource dataset yml file has a binding to the Etsource::Dataset object. Meaning 
# that inside a yml file a method will have the Etsource::Dataset as scope.
#
#     ---
#     heating: <%= get( 'foo', 'bar' ) %>
#
# Above yaml will call the Etsource::Dataset#get with 'foo' and 'bar' as arguments.
# The binding happens in #load_yaml (if it has disappeared search for 'binding').
#
# ------ method_missing meta programming --------------------------------------
#
# @deprecated
#
# @updated I disabled this for now. Not critical to success and the research folks
#  should have enough mental capabilities to prepend every string with a ":".
#
#
# To make life easier for researchers I (sb) decided to let them omit the '' or
# symbol : for the get arguments.
#
#     ---
#     heating: <%= get('foo', 'bar') %>
#     heating: <%= get(foo, bar) %>
#
# I argue that the second example is rather prettier and less prone to typo-bugs.
# It works because the yaml file is bound to the value_box object, therefore foo
# will trigger the ValueBox#method_missing and return :foo back.
#
# ------ Static vs dynamic form yml  ------------------------------------------
#
# The ETsource dataset is split into static and dynamic ymls. The static ones
# don't rely on others and are loaded first. The dynamic form ymls are loaded
# after that, so it can access static dataset using #val and research input
# with #get.
#
# ------ Importing ETsource Form YAML Files  ----------------------------------
#
# To make the ETsource dataset forms dynamic we pass the yml files through an
# ERB handler, and load the output with YAML::load. 
# So that the dynamic yml.erb form templates (the suffix .erb is not needed), can
# access the values of the static datasets and the researchers form input, we 
# add a binding to the yaml files to this Etsource::Dataset object. So calling 
# #get within a yml will call Etsource::Dataset#get
#
#
# ------ DEBT: Refactor this --------------------------------------------------
#
# The YML parsing and import methods really deserve an own class. Right now it's
# a bit a mess.. This should be fixed soon.
#

module Etsource
  class Dataset
<<<<<<< HEAD

    def initialize(etsource = Etsource::Base.new)
      @etsource = etsource
      @datasets = {}
=======
    def initialize(etsource = Etsource::Base.new)
      @etsource = etsource
>>>>>>> staging
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

      # Import static dataset (no value_box formulas)
      @dataset = Qernel::Dataset.new(Hashpipe.hash(country))
      load_area(@dataset, country)
      load_carriers(@dataset, country)
      load_time_curves(@dataset, country)
      @dataset.data[:graph][:graph][:calculated] = false

      load_static_dataset(@dataset, country)
      load_dataset_forms(@dataset, country)

      @dataset
    end

  protected

    def load_area(dataset, country)
      dataset.merge(:area,     load_yaml_with_defaults(country, 'area')[:area])
    rescue => e
      raise "Error loading datasets/:country/area.yml: #{e}"
    end

    def load_carriers(dataset, country)
      dataset.merge(:carrier,  load_yaml_with_defaults(country, 'carriers')[:carriers])
    rescue =>e
      raise "Error loading datasets/:country/carriers.yml: #{e.inspect}"
    end    

    def load_time_curves(dataset, country)
      dataset.time_curves = load_yaml(country, 'time_curves')
    rescue =>e
      raise "Error loading datasets/:country/time_curves.yml: #{e.inspect}"
    end    

    def load_static_dataset(dataset, country)
      # Topology:
      # Load each file, remove :defaults and :globals from hsh, so we don't mess with the rest.
      # merge with dataset.
      topology_dataset_files = Dir.glob(country_dir("{#{country},_defaults}")+"/graph/*.yml")
      topology_dataset_files.each do |file|
        yml_hsh = load_yaml_with_defaults(country, 'graph/'+file.split("/").last) || {}
        yml_hsh.delete(:defaults) 
        yml_hsh.delete(:globals)
        yml_hsh.each do |key,attributes|
          attrs = {}; attributes.each{|k,v| attrs[k.to_sym] = v}
          dataset.merge(group_key(key), hash(key) => attrs)
        end
      end
    rescue => e
      raise "Error loading datasets/:country/graph/*.yml: #{e.inspect}"
    end

    def load_dataset_forms(dataset, country)
      @value_box = InputTool::ValueBox.area(country)

      # Forms:
      # Import dynamic dataset (can reliably lookup information of static dataset)
      # This allows to lookup values from the static dataset
      dynamic_forms = Dir.glob([base_dir, '_forms', '*', "dataset.yml"].join('/'))
      dynamic_forms.each do |file|
        hsh = load_yaml_file(file) || {}
        hsh.delete(:defaults) # remove defaults and globals from hsh
        hsh.delete(:globals)  # otherwise a converter 'defaults' is created
        hsh.each do |key,attributes|
          if key == :area
            dataset.merge(key, attributes)  
          else
            attrs = {}; attributes.each{|k,v| attrs[k.to_sym] = v}
            dataset.merge(group_key(key), hash(key) => attrs)
          end
        end
      end
    end

  public

    # Access value_box through this getter, so we can complain, when ppl use 
    # this functionality inside the dynamic forms.
    def value_box
      unless @value_box
        raise "Trying to access ValueBox/Research Form Data before it was assigned. You probably try to access it from outside the dataset/_forms/"
      end
      @value_box
    end

    # Access values from the static dataset.
    #
    # @param key [String,Symbol] a key of a converter,link or slot "heating_demand-(hot_water)"
    # @param attr_key [String,Symbol] the attribute name.
    #
    def val(key, attr_key)
      @dataset.data[group_key(key)][hash(key)][attr_key.to_sym]
    end

    # @see {InputTool::ValueBox#get}
    #
    def get(*args)
      value_box.get(*args)
    end

    # @see {InputTool::ValueBox#set}
    #
    def shortcut(key, value)
      value_box.set(key, value)
    end
    alias_method :set, :shortcut

    def hash(key)
      Hashpipe.hash(key.to_s.gsub(/\s/, ''))
    end
    
    def all_countries
      Area.all.map(&:region_code)
    end

    def export
      all_countries.each{|c| export_country(c)}
    end

    def export_country(country = 'nl')
      gql = Gql::Gql.new(Scenario.new(Scenario.default_attributes :country => country))
      # Assign datasets w/o calculating. Use future graph (present is precalculated).
      graph.dataset = gql.dataset_clone


      # EDGE/Staging conflict/diverge:
      # Code below this line is more uptodate on staging

      FileUtils.mkdir_p base_dir+"/"+country+"/graph"
      
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
        out << YAML::dump(hsh).gsub("--- \n", '') 
      end

      # ---- Export Area ------------------------------------------------------

      File.open(country_file(country, 'area'), 'w') do |out|
        # Remove first --- line
        out << YAML::dump({:area => graph.dataset.data[:area]}).gsub("--- \n", '') 
      end

      # ---- Export Graph Structure -------------------------------------------

      File.open(country_file(country, 'graph/export'), 'w') do |out|
        # No longer fake yml format
        # out << '---' # Fake YAML format
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