module Qernel
  # Class for getting and setting sector emmissions
  # Behaves much like Qernel::Area, can been seen as an extension of
  # area attributes, scoped for emissions
  class Emissions
    include DatasetAttributes

    dataset_accessors ::Etsource::Dataset.emissions_keys
    attr_accessor :graph

    # TODO: write a spec for scope

    # Queryable object that defers sector methods to main Emissions
    #
    # GQL uses this to scope the sector for easier queries and input/update
    # statements in etsource
    class ScopedSector
      def initialize(emissions, scope)
        @emissions = emissions
        @scope = scope
      end

      def [](attr_name)
        @emissions[scoped_method(attr_name)]
      end

      def []=(attr_name, value)
        @emissions[scoped_method(attr_name)] = value
      end

      def inspect
        "<Qernel::Emissions::ScopedSector #{@scope}>"
      end

      def scoped_method(method_name)
        "#{@scope}_#{method_name}"
      end

      def respond_to_missing?(method_name, include_private = false)
        data_key = scoped_method(method_name).split('=').first

        @emissions.respond_to?(data_key) || super
      end

      def method_missing(method_name, *args)
        data_key = scoped_method(method_name).split('=').first

        if data_key == scoped_method(method_name)
          @emissions[data_key]
        else
          @emissions[data_key] = args.first
        end
      end
    end

    def initialize(graph = nil)
      self.graph = graph unless graph.nil?

      @dataset_key = @key = :emissions_data
    end

    # Public: define the sector scope for access to the hashed emission keys
    #
    # Returns a scoped version of the emissions data
    def scope(sector)
      ScopedSector.new(self, sector)
    end
  end
end
