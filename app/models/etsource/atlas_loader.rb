# frozen_string_literal: true

module Etsource
  module AtlasLoader
    # An abstract class providing useful methods to subclasses, but not meant to be used directly.
    module Common
      include Instrumentable

      # Public: Creates a new AtlasLoader.
      #
      # directory - Path to the directory in which the cached files are stored.
      #
      # Returns an AtlasLoader::Base
      def initialize(directory)
        @directory = directory
      end

      # Public: The path to the .pack file directory.
      #
      # Returns a Pathname.
      def directory
        @directory
      end

      # Public: The Atlas::ProductionMode for the region specified by the given dataset key.
      #
      # Returns an Atlas::ProductionMode.
      def load(dataset_key)
        location = data_path(dataset_key)

        raise "No Atlas data for #{dataset_key.inspect} at #{location}" unless location.file?

        Atlas::ProductionMode.new(parse(location.read))
      end

      # Public: Forces calculation of all the regions which are enabled for use in ETEngine.
      #
      # Provide a block to which each dataset key will be yielded when loaded.
      #
      # Returns nothing.
      def reload!
        expire_all!
      end

      # Public: Calculates a single region, as specified by the given dataset key.
      #
      # Returns nothing.
      def calculate!(dataset_key)
        instrument("etsource.loader: atlas+ref(#{dataset_key.inspect})") do
          dataset = Atlas::Dataset.find(dataset_key)
          runner  = Atlas::Runner.new(dataset)

          runner.calculate

          contents = dump(Atlas::Exporter.dump(runner))
          location = data_path(dataset_key)

          FileUtils.mkdir_p(location.dirname)
          File.write(location, contents, mode: 'wb')
        end
      end

      # Public: Removes all the ProductionMode .pack files.
      #
      # Returns nothing.
      def expire_all!
        Pathname.glob(@directory.join('*.pack')).each(&:delete) if @directory.directory?
      end

      private

      # Internal: Returns the path to an exported .pack file, for the given dataset key.
      #
      # Returns a Pathname.
      def data_path(dataset_key)
        @directory.join("#{dataset_key}.pack")
      end

      # Internal: Given the contents of a saved dataset file, parses the data into a Ruby hash.
      #
      # Returns a hash.
      def parse(data)
        hash = MessagePack.unpack(data)

        # MessagePack converts hash keys from symbols to strings; we need to convert them back. The
        # keys for the nested hashes (one per document) don't matter, since ActiveDocument/Virtus
        # will take either.
        hash.transform_values(&:symbolize_keys!)
      end

      # Internal: Creates a string representing the exported data.
      #
      # data - A Ruby hash to be converted to a string for storage on disk.
      #
      # Returns a String.
      def dump(data)
        MessagePack.pack(data)
      end

      # Internal: Determines if a region has been calculated.
      #
      # Returns true or false.
      def calculated?(dataset_key)
        data_path(dataset_key).file?
      end
    end

    # An Atlas ProductionMode loader which expects the exported .pack files to have been calculated
    # already. They should be located in tmp/atlas.
    class PreCalculated
      include Common

      # Public: Forces calculation of all the regions which are enabled for use in ETEngine.
      #
      # Returns nothing.
      def reload!(progress: false)
        super()

        Parallel.each(
          Etsource::Dataset.region_codes(refresh: true),
          progress: progress && { title: 'Calculating datasets' }
        ) do |code|
          calculator = -> { calculate!(code) }

          yield(code, calculator) if block_given?

          # In case the user failed to call the calculator in their block, or if no block was given.
          calculator.call unless calculated?(code)
        end
      end
    end

    # An Atlas ProductionMode loader which runs the Atlas queries and Refinery calcualtions the
    # first time a region is loaded in ETEngine. This makes working with ETSource easier in
    # development, but is not recommended for production.
    class Lazy
      include Common

      # Public: Creates a new AtlasLoader.
      #
      # directory - Path to the directory in which the cached files are stored.
      #
      # Returns an AtlasLoader::Base
      def initialize(directory)
        super(directory.join('lazy'))
      end

      # Public: The Atlas::ProductionMode for the region specified by the given dataset key.
      # Lazy-loads the dataset by calculating it in Atlas and Refinery if it does not already exist.
      #
      # Returns an Atlas::ProductionMode.
      def load(dataset_key)
        location = data_path(dataset_key)

        # Lazy load the dataset if it doesn't exist yet.
        calculate!(dataset_key) unless location.file?

        super
      end
    end
  end
end
