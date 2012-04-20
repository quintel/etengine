
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
      @etsource = Etsource::Base.instance

      @country  = country
      @dataset = Qernel::Dataset.new(Hashpipe.hash(country))
      @hsh = {}
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
        raise "Trying to load a dataset with region code '#{country}' but it does not exist. Should be: #{country_dir(country)}"
      end

      dataset_hash = load_dataset_hash
      dataset_hash.delete(:defaults)
      dataset_hash.delete(:mixins)

      @dataset.data = dataset_hash
      @dataset.data[:area] ||= {:area_data => {}}
      @dataset.data[:graph][:graph] = {:calculated => false}

      # load_dataset_wizards if @etsource.load_wizards?

      @dataset
    end

    # Return all the carrier keys we have defined in the dataset.
    # (used to dynamically generate some methods)
    def carrier_keys
      hsh = load_dataset_hash
      hsh[:carriers].andand.keys || []
    end

    def raw_hash
      load_dataset_hash({})
    end

  #########
  protected
  #########

    def load_dataset_hash(yaml_pack_options = nil)
      yaml_pack_options ||= yaml_box_opts
      yaml_pack_options[:base_dir] = country_dir('_defaults')

      default_files   = Dir.glob(country_dir('_defaults')+"/**/*.yml")
      default_dataset = YamlPack.new(default_files, yaml_pack_options).load_deep_merged

      yaml_pack_options[:base_dir] = country_dir
      country_files   = Dir.glob(country_dir+"/**/*.yml")
      country_dataset = YamlPack.new(country_files, yaml_pack_options).load_deep_merged

      default_dataset.deep_merge(country_dataset)
    end

    # The following Proc transforms the keys of the dataset. It converts
    # strings into symbols. For the special converter,slot and link keys
    # it calculates a hash, for quicker hash lookups.
    #
    # :graph
    #   :converter_xyz # <--- special rule for these keys
    #      :demand
    KEY_CONVERTER = Proc.new do |key, converter_keys|
      # check that we are at the 2nd level in the 'graph' tree. Without the
      # length check we would make hashes out of attribute names.
      if converter_keys.first == 'graph' && converter_keys.length == 1
        Hashpipe.hash(key)
      else
        key.respond_to?(:to_sym) ? key.to_sym : key
      end
    end

    # options for yaml_pack loader
    # - Always attach datasets/_includes/header.yml. There we can define mixins.
    # - folders after base_dir, will get corresponding nested keys in the hash
    #   e.g.: /graph/export.yml => {:graph => {...contents of file...}}
    #
    def yaml_box_opts(base_dir = nil)
      {
        key_converter: KEY_CONVERTER,
        # base_dir makes a) nesting hashes into folders possible
        # and b) allows for including other files.
        base_dir: base_dir
      }
    end

    # ---- Import Dynamic with Research Data ----------------------------------

    def load_dataset_wizards
      research_dataset = InputTool::ResearchDataset.area(country)
      # Import dynamic dataset (can reliably lookup information of static dataset)
      # This allows to lookup values from the static dataset
      Dir.glob([base_dir, '_wizards', '*', "transformer.yml"].join('/')).each do |file|
        wizard   = ::Etsource::Wizard.new(file.split("/")[-2])
        renderer = ::Etsource::Dataset::Renderer.new(file, research_dataset, @dataset, wizard.config)

        hsh = renderer.result
        renderer.save_compiled_yaml(file.gsub('datasets', "compiled/#{country}"))
        merge_hash_into_dataset!(hsh)
      end
    end

    def merge_hash_into_dataset!(hsh)
      # Dont make converters with keys :defaults and :globals
      hsh.delete(:defaults)
      hsh.delete(:globals)

      hsh.each do |key,attributes|
        if key == :area
          # area is a special kid for now. dont hash keys or groups
          @dataset.merge(key, attributes)
        else
          raise "No attributes/hashing defined for key `#{key}` in following data bucket. Check the dataset. \n `#{hsh.inspect}`" if attributes.nil?
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

    def base_dir
      "#{@etsource.export_dir}/datasets"
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

