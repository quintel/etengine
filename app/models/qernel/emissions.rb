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
  # Joining the CSV columns into one key loses the column boundaries
  # (components such as "non_energetic" contain the separator), so the
  # import also builds an index preserving the structure (see
  # Etsource::Dataset::Import#build_emissions_index). Lookups construct
  # exact keys from the index rather than parsing them.
  #
  # == Year Handling
  #
  # Year parameter defaults to the dataset's analysis_year when not
  # specified. Multiple years coexist in the same dataset (e.g., 1990
  # baseline, 2023 current).
  class Emissions
    include DatasetAttributes

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
        unless emissions.valid_scope?(scope)
          raise ArgumentError, "unknown emissions scope: #{scope}"
        end

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

      # Getters and setters for each GHG in the dataset (e.g. scoped.co2,
      # scoped.co2 = 1.0), delegated to []/[]=. The GHG set comes from the
      # emissions index, so a new gas in the CSV needs no code change here.
      def method_missing(name, *args)
        return super unless ghg?(name)

        if name.end_with?('=')
          self[name.to_s.delete_suffix('=')] = args.first
        else
          self[name]
        end
      end

      def respond_to_missing?(name, include_private = false)
        ghg?(name) || super
      end

      private

      def ghg?(name)
        @emissions.ghgs.key?(name.to_s.delete_suffix('=').to_sym)
      end
    end

    def initialize(graph = nil)
      self.graph = graph unless graph.nil?

      @dataset_key = @key = :emissions_data
    end

    # Public: Aggregates emissions for a sector, use, ghg, and year.
    #
    # Sums the value of every subsector belonging to the given sector. When
    # given a full subsector key instead of a sector, returns its single
    # value. Includes runtime UPDATE modifications.
    #
    # == Examples
    #
    #   # Sum all energy sector energetic CO2 emissions for 2023
    #   emissions.sum(:energy, :energetic, :co2, 2023)
    #   # => 500.25
    #
    #   # Single subsector
    #   emissions.sum(:buildings_non_specified, :energetic, :other_ghg, 2023)
    #   # => 55.64
    #
    #   # Default year (analysis_year from dataset)
    #   emissions.sum(:agriculture, :non_energetic, :other_ghg)
    #   # => 18863.47
    #
    # Returns a Float; 0.0 when nothing matches.
    def sum(sector, use, ghg, year = nil)
      year ||= default_year

      subsector_keys(sector).sum do |subsector|
        self[:"#{subsector}_#{use}_#{ghg}_#{year}"] || 0.0
      end
    end

    # Public: define the sector scope for access to the hashed emission keys
    #
    # sector - Scope identifier (e.g., :buildings_non_specified_energetic).
    #          Must exist in the dataset; raises ArgumentError otherwise.
    # year   - Optional year (defaults to analysis_year). Used to target a
    #          specific year for UPDATE operations.
    #
    # Returns a scoped version of the emissions data
    def scope(sector, year = nil)
      ScopedSector.new(self, sector, year)
    end

    # Public: Whether the scope (sector_subsector_use) exists in the dataset.
    def valid_scope?(scope)
      index[:scopes].key?(scope.to_sym)
    end

    # Public: The GHG types present in the dataset (ghg => true).
    def ghgs
      index[:ghgs]
    end

    # Returns the default year for emissions queries.
    # Uses the area's analysis_year if graph is present, nil otherwise.
    def default_year
      graph&.area&.analysis_year
    end

    EMPTY_INDEX = { sectors: {}, subsectors: {}, scopes: {}, ghgs: {} }.freeze

    # The structured emissions index built at import time.
    # See Etsource::Dataset::Import#build_emissions_index.
    def index
      @index ||=
        (dataset && dataset.data[:emissions][:emissions_index]) || EMPTY_INDEX
    end

    private

    # An exact sector maps to its subsector keys; an exact subsector key
    # maps to itself; anything else matches nothing.
    def subsector_keys(sector)
      key = sector.to_s.tr('-.', '_').downcase.to_sym
      index[:sectors][key] || (index[:subsectors].key?(key) ? [key] : [])
    end
  end
end
