# Sets up the necessary stubs to use the fixture version of ETSource located
# at spec/fixtures/etsource.
module ETSourceFixtureHelper
  # A custom Atlas loader which will not attempt to calculate the dataset in
  # Atlas and Refinery. It also uses YAML (since it is easier for humans to
  # edit), instead of MessagePack.
  class AtlasTestLoader < Etsource::AtlasLoader::PreCalculated
    def calculate!(*)
      # noop
    end

    def reload!(*)
      # noop
    end

    def load(dataset_key)
      self.class.loaded[dataset_key] ||= super
    end

    # Speed up tests by caching the loaded data.
    def self.loaded
      @loaded ||= {}
    end

    #######
    private
    #######

    # Parses the static YAML file. Since the Atlas::ProductionLoader expects
    # a hash containing *all* the attributes, and the static file contains
    # only the demands and shares, we merge the attributes from the original
    # documents with the static data to create the complete hash.
    def parse(data)
      data = YAML.load(data)

      Atlas::GraphConfig.configs.each do |config|
        config.node_class.all.each do |node|
          data[config.node_class.name][node.key] =
            node.to_hash.deep_merge(data[config.node_class.name][node.key] || {})
        end

        config.edge_class.all.each do |edge|
          data[config.edge_class.name][edge.key] =
            edge.to_hash.deep_merge(data[config.edge_class.name][edge.key] || {})
        end
      end

      data
    end

    def dump(data)
      YAML.dump(data)
    end

    def data_path(dataset_key)
      super.dirname.dirname.join("../atlas/#{ dataset_key }.yml")
    end
  end
end # EtmFixtureHelper
