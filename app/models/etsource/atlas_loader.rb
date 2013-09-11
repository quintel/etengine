module Etsource
  module AtlasLoader
    # An abstract class providing useful methods to subclasses, but not meant
    # to be used directly.
    module Common
      include Instrumentable

      # Public: Creates a new AtlasLoader.
      #
      # directory - Path to the directory in which the YML files are stored.
      #
      # Returns an AtlasLoader::Base
      def initialize(directory)
        @directory = directory
      end

      # Public: The path to the YAML file directory.
      #
      # Returns a Pathname.
      def directory
        @directory
      end

      # Public: The Atlas::ProductionMode for the region specified by the
      # given dataset key.
      #
      # Returns an Atlas::ProductionMode.
      def load(dataset_key)
        location = data_path(dataset_key)

        unless location.file?
          fail "No Atlas data for #{ dataset_key.inspect } at #{ location }"
        end

        Atlas::ProductionMode.new(parse(location.read))
      end

      # Public: Forces calculation of all the regions which are enabled for
      # use in ETEngine.
      #
      # Provide a block to which each dataset key will be yielded when loaded.
      #
      # Returns nothing.
      def reload!
        expire_all!
      end

      # Public: Calculates a single region, as specified by the given dataset
      # key.
      #
      # Returns nothing.
      def calculate!(dataset_key)
        instrument("etsource.loader: atlas+ref(#{ dataset_key.inspect })") do
          graph   = Atlas::GraphBuilder.build
          dataset = Atlas::Dataset.find(dataset_key)
          runner  = Atlas::Runner.new(dataset, graph)

          runner.calculate

          contents = dump(Atlas::Exporter.dump(runner.refinery_graph))
          location = data_path(dataset_key)

          FileUtils.mkdir_p(location.dirname)
          File.write(location, contents, mode: 'wb')
        end
      end

      # Public: Removes all the ProductionMode YAML files.
      #
      # Returns nothing.
      def expire_all!
        if @directory.directory?
          Pathname.glob(@directory.join("*.yml")).each(&:delete)
        end
      end

      #######
      private
      #######

      # Internal: Returns the path to an exported YAML file, for the given
      # dataset key.
      #
      # Returns a Pathname.
      def data_path(dataset_key)
        @directory.join("#{ dataset_key }.pack")
      end

      # Internal: Given the contents of a saved dataset file, parses the data
      # into a Ruby hash.
      #
      # Returns a hash.
      def parse(data)
        hash = MessagePack.unpack(data)

        # MessagePack converts hash keys from symbols to strings; we need to
        # convert them back. The keys for the nested hashes (one per document)
        # don't matter, since ActiveDocument/Virtus will take either.
        { nodes: hash['nodes'].symbolize_keys!,
          edges: hash['edges'].symbolize_keys! }
      end

      # Internal: Creates a string representing the exported data.
      #
      # data - A Ruby hash to be converted to a string for storage on disk.
      #
      # Returns a String..
      def dump(data)
        MessagePack.pack(data)
      end
    end # Base

    # An Atlas ProductionMode loader which expects the exported YAML files to
    # have been calculated already. They should be located in tmp/atlas.
    class PreCalculated
      include Common

      # Public: Forces calculation of all the regions which are enabled for
      # use in ETEngine.
      #
      # Returns nothing.
      def reload!
        super

        Etsource::Dataset.region_codes.each do |code|
          calculate!(code)
          yield code if block_given?
        end
      end
    end # PreCalculated

    # An Atlas ProductionMode loader which runs the Atlas queries and Refinery
    # calcualtions the first time a region is loaded in ETEngine. This makes
    # working with ETSource easier in development, but is not recommended for
    # production.
    class Lazy
      include Common

      # Public: Creates a new AtlasLoader.
      #
      # directory - Path to the directory in which the YML files are stored.
      #
      # Returns an AtlasLoader::Base
      def initialize(directory)
        super(directory.join('lazy'))
      end

      # Public: The Atlas::ProductionMode for the region specified by the
      # given dataset key. Lazy-loads the dataset by calculating it in Atlas
      # and Refinery if it does not already exist.
      #
      # Returns an Atlas::ProductionMode.
      def load(dataset_key)
        location = data_path(dataset_key)

        # Lazy load the dataset if it doesn't exist yet.
        calculate!(dataset_key) unless location.file?

        super
      end
    end # Lazy
  end # AtlasLoader
end # Etsource
