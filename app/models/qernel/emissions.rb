module Qernel
  # Class for getting and setting emissions data
  # Behaves much like Qernel::Area, can be seen as an extension of
  # area attributes, scoped for emissions
  #
  # Emissions data is loaded from CSV files in ETSource with structure:
  #   etm_sector, etm_subsector, use, ghg, unit, value
  #
  # Keys are generated as: sector_[subsector_]use_ghg[_year]
  # Example: buildings_non_specified_energetic_co2
  class Emissions
    include DatasetAttributes

    attr_accessor :graph

    # Queryable object that provides scoped access to emissions data
    #
    # GQL uses this to scope the sector for easier queries and input/update
    # statements in etsource
    #
    # Example:
    #   EMISSIONS(households, energetic) returns a ScopedSector
    #   Then UPDATE can call: scoped.co2 = 100.0
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

      def method_missing(method_name, *args)
        data_key = scoped_method(method_name.to_s.sub(/=$/, ''))
        is_setter = method_name.to_s.end_with?('=')

        if is_setter
          # Validate that the emission key exists in the dataset
          unless @emissions.dataset_has_key?(data_key)
            raise NoMethodError,
              "undefined method `#{method_name}' for #{inspect} - " \
              "emission key '#{data_key}' not found in dataset"
          end

          # Setters use dataset_set which converts to symbol internally
          @emissions[data_key] = args.first
        else
          # Getters use dataset_get which works with the key as-is
          @emissions[data_key]
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        # Don't claim to respond to :query - UPDATE uses this to unwrap objects
        return false if method_name.to_sym == :query

        # For setters, check if the emission key exists in the dataset
        if method_name.to_s.end_with?('=')
          data_key = scoped_method(method_name.to_s.sub(/=$/, ''))
          @emissions.dataset_has_key?(data_key)
        else
          # Getters always respond (may return nil if key doesn't exist)
          true
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

    # Public: Check if a key exists in the loaded emissions dataset
    #
    # key - String or Symbol representing the emission key
    #
    # Returns Boolean
    def dataset_has_key?(key)
      return false unless dataset_attributes

      # Check both string and symbol keys since datasets may use either
      dataset_attributes.key?(key.to_s) || dataset_attributes.key?(key.to_sym)
    end
  end
end
