
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

    STATIC_REGION_FILES = Rails.root.join('tmp')

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

      data = default_dataset.deep_merge(country_dataset)

      data[:graph] = load_graph_dataset
      data
    end

    # Internal: Reads the shares, demands, and other regional data from the
    # production-mode Atlas documents, populating the +:graph+ part of the
    # dataset.
    #
    # Returns a hash containing the data.
    def load_graph_dataset
      graph_dataset = {}

      graph_objects = Atlas::ProductionMode.new(
        YAML.load_file(STATIC_REGION_FILES.join('static.yml')))

      graph_objects.nodes.each { |node| import_node!(node, graph_dataset) }
      graph_objects.edges.each { |edge| import_edge!(edge, graph_dataset) }

      graph_dataset
    end

    # Internal: Given an Atlas node, determines if that node should have a
    # useful demand attribute, or an expected demand attribute.
    #
    # Returns true or false.
    def demand_attribute(node)
      @demand_node_table ||=
        Atlas::Node.all.each_with_object({}) do |node, table|
          table[node.key] = node.groups.include?(:preset_demand)
        end

      @demand_node_table[node.key] ? :preset_demand : :demand_expected_value
    end

    # Internal: Converts the attributes from a production-mode Atlas node and
    # sets the relevant data onto the ETEngine :graph dataset.
    #
    # Also imports slots.
    #
    # node    - The Atlas::Node.
    # dataset - The :graph part of the dataset.
    #
    # Returns nothing.
    def import_node!(node, dataset)
      attributes = node.attributes
      attributes.delete(:demand)

      if (demand_attr = demand_attribute(node)) == :preset_demand
        attributes[:preset_demand] = val(node, :demand) * 1_000_000_000
      elsif demand = node.demand
        attributes[:demand_expected_value] = demand * 1_000_000_000
      end

      # Temporary until query-based attributes in Atlas are no longer defined
      # as a method with the same name, but instead use AD#val.
      if node.is_a?(Atlas::Node::CentralProducer)
        attributes[:full_load_hours] = node.full_load_hours(@country)
      end

      dataset[Hashpipe.hash(node.key)] = attributes

      (node.in_slots + node.out_slots).each do |slot|
        import_slot!(slot, dataset)
      end
    end

    # Internal: Converts the attributes from a production-mode Atlas slot and
    # sets the conversion and other relevant attributes onto the dataset.
    #
    # slot    - The Atlas::Slot.
    # dataset - The :graph part of the dataset.
    #
    # Returns nothing.
    def import_slot!(slot, dataset)
      key = FromAtlas.slot_key(slot.node.key, slot.carrier, slot.direction)

      dataset[Hashpipe.hash(key)] = if slot.is_a?(Atlas::Slot::Elastic)
        {}
      else
        { conversion: val(slot, :share) }
      end
    end

    # Internal: Converts the attributes from a production-mode Atlas edge and
    # sets the attributes onto the dataset.
    #
    # edge    - The Atlas::Edge.
    # dataset - The :graph part of the dataset.
    #
    # Returns nothing.
    def import_edge!(edge, dataset)
      attributes = edge.attributes

      attributes.delete(:demand)
      attributes.delete(:parent_share)

      if edge.type == :share
        attributes[:share] = attributes.delete(:child_share)
      end

      dataset[Hashpipe.hash(FromAtlas.link_key(edge))] = attributes
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

    # Internal: Given a production-mode Atlas object and an attribute name,
    # returns the value of the attribute, or raises an error if it is nil.
    #
    # Returns the value.
    def val(document, attribute)
      unless value = document.public_send(attribute)
        raise "#{ document.inspect } has no #{ attribute.inspect } value"
      end

      value
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

