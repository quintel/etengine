module Qernel
  # Stores and provides access to emissions data loaded from the dataset.
  # Emissions data includes CO2 and other GHG emissions across different sectors.
  #
  # The class dynamically generates accessor methods for all emission keys
  # found in the dataset, allowing both direct access and scoped access by sector.
  #
  # Example:
  #   emissions = Qernel::Emissions.new(graph)
  #   emissions.buildings_non_specified_energetic_other_ghg
  #   # => 2796620.0
  #
  #   # Using scoped access for cleaner UPDATE statements:
  #   sector = emissions.scope(:buildings_non_specified)
  #   sector.energetic_other_ghg
  #   # => 2796620.0
  #
  class Emissions
    include DatasetAttributes

    dataset_accessors ::Etsource::Dataset.emissions_keys
    attr_accessor :graph

    # Queryable object that defers sector methods to main Emissions.
    # This allows cleaner GQL syntax for UPDATE statements.
    #
    # Example:
    #   sector = emissions.scope(:households)
    #   sector.other_ghg = 10.0
    #   # Sets emissions.households_other_ghg = 10.0
    #
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
          # Getter
          @emissions[data_key]
        else
          # Setter
          @emissions[data_key] = args.first
        end
      end
    end

    def initialize(graph = nil)
      self.graph = graph unless graph.nil?
      @dataset_key = @key = :emissions_data
    end

    # Creates a scoped accessor for a specific sector.
    # This is used by the EMISSIONS() GQL function to support UPDATE statements.
    #
    # Returns a ScopedSector
    def scope(sector)
      ScopedSector.new(self, sector)
    end
  end
end
