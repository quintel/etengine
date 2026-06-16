module Qernel
  # Class for getting and setting emissions data.
  # Behaves much like Qernel::Area, can be seen as an extension of
  # area attributes, scoped for emissions.
  #
  # == Data Structure
  #
  # Emissions data is loaded from CSV files in ETSource with structure:
  #   etm_sector, etm_subsector, use, ghg, year, unit, value
  #
  # Values are stored flat, keyed as: sector_subsector_use_ghg_year
  # Examples:
  #   - buildings_non_specified_energetic_other_ghg_2023
  #   - energy_electricity_and_heat_production_energetic_co2_1990
  #
  # == Year Handling
  #
  # Year parameter defaults to the dataset's analysis_year when not
  # specified. Multiple years coexist in the same dataset (e.g., 1990
  # baseline, 2023 current).
  class Emissions
    include DatasetAttributes

    dataset_accessors ::Etsource::Dataset.emissions_keys
    attr_accessor :graph

    # Queryable object that provides scoped access to emissions data
    #
    # GQL uses this to scope the sector for easier queries and input/update
    # statements in etsource
    #
    # Example:
    #   EMISSIONS(households_non_specified, energetic) returns a ScopedSector
    #   Then UPDATE can call: scoped.co2 = 100.0
    class ScopedSector
      def initialize(emissions, scope, year = nil)
        @emissions = emissions
        @scope = scope
        @year = year
      end

      def [](attr_name)
        @emissions[scoped_method(attr_name).to_sym]
      end

      def []=(attr_name, value)
        @emissions[scoped_method(attr_name).to_sym] = value
      end

      def inspect
        "<Qernel::Emissions::ScopedSector #{@scope}>"
      end

      def scoped_method(method_name)
        year = @year || @emissions.default_year
        "#{@scope}_#{method_name}_#{year}"
      end

      def respond_to_missing?(method_name, include_private = false)
        attr_name = method_name.to_s.delete_suffix('=')
        data_key = scoped_method(attr_name)

        @emissions.respond_to?(data_key) || super
      end

      def method_missing(method_name, *args)
        attr_name = method_name.to_s.delete_suffix('=')
        data_key = scoped_method(attr_name).to_sym

        if method_name.to_s.end_with?('=')
          @emissions[data_key] = args.first
        else
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
    # sector - Scope identifier (e.g., :buildings_non_specified_energetic).
    # year   - Optional year (defaults to analysis_year). Used to target a
    #          specific year for UPDATE operations.
    #
    # Returns a scoped version of the emissions data
    def scope(sector, year = nil)
      ScopedSector.new(self, sector, year)
    end

    # Returns the default year for emissions queries.
    # Uses the area's analysis_year if graph is present, nil otherwise.
    def default_year
      graph&.area&.analysis_year
    end
  end
end
