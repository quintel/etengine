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
  # Values are stored flat, keyed as: sector_subsector_use_ghg[_1990]
  # Examples:
  #   - buildings_non_specified_energetic_other_ghg
  #   - energy_electricity_and_heat_production_energetic_co2_1990
  #
  # == Year Handling
  #
  # The present year is implicit and carries no suffix. Only the historic
  # 1990 baseline is suffixed with its year, so both can coexist in the
  # same dataset.
  class Emissions
    include DatasetAttributes

    dataset_accessors ::Etsource::Dataset.emissions_keys
    attr_accessor :graph

    # Public: The flat store key for the given parts, e.g. (sector, use, ghg).
    # The single place the `parts_joined_by_underscores[_1990]` schema lives.
    #
    # Returns a Symbol.
    def self.key_for(*parts, year: nil)
      [*parts, (1990 if year.to_i == 1990)].compact.join('_').to_sym
    end

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
        @emissions[scoped_method(attr_name)]
      end

      def []=(attr_name, value)
        @emissions[scoped_method(attr_name)] = value
      end

      def inspect
        "<Qernel::Emissions::ScopedSector #{@scope}>"
      end

      def scoped_method(method_name)
        Emissions.key_for(@scope, method_name.to_s.delete_suffix('='), year: @year)
      end

      def respond_to_missing?(method_name, include_private = false)
        if method_name.to_s.end_with?('=')
          scope_exists?
        else
          @emissions.respond_to?(scoped_method(method_name)) || super
        end
      end

      def method_missing(method_name, *args)
        key = scoped_method(method_name)

        if method_name.to_s.end_with?('=')
          unless scope_exists?
            raise NoMethodError, "undefined method `#{method_name}' for #{inspect}"
          end

          @emissions[key] = args.first
        else
          @emissions[key]
        end
      end

      private

      # Scoped writes work for any region that has the scope.
      def scope_exists?
        prefix = "#{@scope}_"
        @emissions.dataset_attributes.keys.any? { |key| key.to_s.start_with?(prefix) }
      end
    end

    def initialize(graph = nil)
      self.graph = graph unless graph.nil?

      @dataset_key = @key = :emissions_data
    end

    # Public: define the sector scope for access to the hashed emission keys
    #
    # sector - Scope identifier (e.g., :buildings_non_specified_energetic).
    # year   - Optional year. Pass 1990 to target the historic baseline.
    #
    # Returns a scoped version of the emissions data
    def scope(sector, year = nil)
      ScopedSector.new(self, sector, year)
    end

    # Public: The stored value for (sector, use, ghg), or nil when the store
    # has no such key. Pass year: 1990 to read the historic baseline.
    def value_for(sector, use, ghg, year: nil)
      self[self.class.key_for(sector, use, ghg, year: year)]
    end

    # Public: Sums the store over (sector, use) pairs for one GHG. Pairs
    # without a stored value count as zero.
    def sum_pairs(pairs, ghg, year: nil)
      pairs.sum { |sector, use| value_for(sector, use, ghg, year: year) || 0.0 }
    end
  end
end
