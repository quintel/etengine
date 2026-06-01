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
      # Valid GHG types that can be used in emission keys
      VALID_GHG_TYPES = %w[co2 other_ghg n2o ch4 hfc pfc sf6 nf3].freeze
      VALID_GHG_PATTERN = /^(#{VALID_GHG_TYPES.join('|')})(_\d{4})?$/.freeze

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

      def valid_emission_key?(attr_name)
        # Check if attribute name matches valid GHG pattern (e.g., co2, other_ghg, co2_1990)
        attr_name.to_s.match?(VALID_GHG_PATTERN)
      end

      def respond_to_missing?(method_name, include_private = false)
        attr_name = method_name.to_s.sub(/=$/, '')
        valid_emission_key?(attr_name) || super
      end

      def method_missing(method_name, *args)
        attr_name = method_name.to_s.sub(/=$/, '')
        data_key = scoped_method(attr_name)  # Keep as string for compatibility
        is_setter = method_name.to_s.end_with?('=')

        # Only validate setters - getters can return nil for any key
        if is_setter && !valid_emission_key?(attr_name)
          super
        end

        if is_setter
          # Setters use dataset_set which converts to symbol internally
          @emissions[data_key] = args.first
        else
          # Getters use dataset_get which works with the key as-is
          @emissions[data_key]
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
