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
  # Keys are generated as: sector_subsector_use_ghg_year
  # Examples:
  #   - buildings_non_specified_energetic_other_ghg_2023
  #   - energy_electricity_and_heat_production_energetic_co2_1990
  #
  # == Aggregation via sum()
  #
  # The sum() method aggregates emissions across subsectors for a given sector,
  # use, ghg, and year combination. This allows queries like:
  #   EMISSIONS(energy, energetic, co2, 2023)
  # to return the sum of all energy subsectors' energetic CO2 emissions for 2023.
  #
  # == Year Handling
  #
  # Year parameter defaults to the dataset's analysis_year when not specified.
  # Multiple years can coexist in the same dataset (e.g., 1990 baseline, 2023 current).
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
    #   EMISSIONS(households, energetic) returns a ScopedSector
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
        # Remove '=' suffix if present before generating scoped key
        clean_method = method_name.to_s.delete_suffix('=')
        data_key = scoped_method(clean_method).to_sym

        # Setters: validate scope exists (allows runtime values for valid scopes)
        # Getters: require exact key to exist (strict validation)
        if method_name.to_s.end_with?('=')
          scope_exists?
        else
          @emissions.dataset_attributes&.key?(data_key) || super
        end
      end

      def method_missing(method_name, *args)
        # Remove '=' suffix if present before generating scoped key
        clean_method = method_name.to_s.delete_suffix('=')
        data_key = scoped_method(clean_method).to_sym

        # Setter: validate scope exists (allows runtime values for valid scopes)
        # Getter: require exact key to exist (strict validation)
        if method_name.to_s.end_with?('=')
          unless scope_exists?
            raise NoMethodError, "undefined method `#{method_name}' for #{inspect}"
          end
          @emissions[data_key] = args.first
        else
          unless @emissions.dataset_attributes&.key?(data_key)
            raise NoMethodError, "undefined method `#{method_name}' for #{inspect}"
          end
          @emissions[data_key]
        end
      end

      private

      # Validates that the scope (sector_subsector_use) exists in the dataset.
      # This allows UPDATE operations to set runtime values for valid scopes,
      # while preventing completely invalid scopes like 'invalid_sector_energetic'.
      #
      # Returns true if at least one key matching the scope prefix exists.
      def scope_exists?
        prefix = "#{@scope}_"

        return false unless @emissions.dataset_attributes

        @emissions.dataset_attributes.keys.any? do |key|
          key.to_s.start_with?(prefix)
        end
      end
    end

    def initialize(graph = nil)
      self.graph = graph unless graph.nil?

      @dataset_key = @key = :emissions_data
    end

    # Public: Aggregates emissions across subsectors for a given sector, use, ghg, and year.
    #
    # This method sums all emissions entries that match the specified sector prefix,
    # use type, GHG type, and year. It aggregates across all subsectors within the
    # specified sector.
    #
    # == Examples
    #
    #   # Sum all energy sector energetic CO2 emissions for 2023
    #   # (aggregates electricity production, fuels production, etc.)
    #   emissions.sum(:energy, :energetic, :co2, 2023)
    #   # => 500.25
    #
    #   # Get single subsector (no aggregation needed, but still uses sum)
    #   emissions.sum(:buildings_non_specified, :energetic, :other_ghg, 2023)
    #   # => 55.64
    #
    #   # Use default year (analysis_year from dataset)
    #   emissions.sum(:agriculture, :non_energetic, :other_ghg)
    #   # => 18863.47
    #
    # == Parameters
    #
    # sector - Sector name or full subsector key (e.g., :energy, :buildings_non_specified)
    #          Normalized: dashes/dots → underscores, lowercased
    # use    - Use type (:energetic or :non_energetic)
    # ghg    - GHG type (:co2 or :other_ghg)
    # year   - Optional year (Integer). Defaults to graph.area.analysis_year if not specified
    #
    # == Returns
    #
    # Float sum of all matching emissions. Returns 0 if no matches found.
    # Includes any runtime UPDATE modifications to emission values.
    def sum(sector, use, ghg, year = nil)
      year ||= default_year
      prefix = sector.to_s.tr('-.', '_').downcase
      use_str = use.to_s
      ghg_str = ghg.to_s
      year_str = year.to_s

      # Match known emission types explicitly to avoid substring collisions.
      # Use non-greedy match (.*?) and longest-first alternations to ensure
      # "non_energetic" and "other_ghg" are matched correctly.
      # This replaces the negative lookbehind with explicit enumeration of valid values.
      pattern = /^#{Regexp.escape(prefix)}.*?_(non_energetic|energetic)_(other_ghg|co2)_#{Regexp.escape(year_str)}$/

      dataset_attributes.keys.sum do |key|
        match = key.to_s.match(pattern)
        # Verify exact match on use and ghg components
        if match && match[1] == use_str && match[2] == ghg_str
          dataset_get(key) || 0
        else
          0
        end
      end
    end

    # Public: define the sector scope for access to the hashed emission keys
    #
    # sector - Sector identifier (e.g., :buildings_non_specified_energetic)
    # year   - Optional year (defaults to analysis_year). Used to target specific year for UPDATE operations.
    #
    # Returns a scoped version of the emissions data
    def scope(sector, year = nil)
      ScopedSector.new(self, sector, year)
    end

    # Returns the default year for emissions queries.
    # Uses the area's analysis_year if graph is present, nil otherwise.
    def default_year
      graph&.area.analysis_year
    end
  end
end
