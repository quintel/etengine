# frozen_string_literal: true

module Etsource
  # Loads data relating to the calculation of molecule flows based on the energy graph.
  module Molecules
    CACHE_KEYS = %w[
      molecules.from_energy_keys
      molecules.from_molecules_keys
    ].freeze

    module_function

    # Internal: Computes the list of molecule graph nodes which have a molecule_conversion
    # attribute.
    #
    # These nodes will receive a demand based on flows in the energy graph.
    #
    # Returns an Array of Symbols.
    def from_energy_keys
      molecule_cache['molecules.from_energy_keys']
    end

    # Internal: Computes the list of molecule graph nodes which have a molecule_conversion
    # attribute.
    #
    # These nodes will receive a demand based on flows in the energy graph.
    #
    # Returns an Array of Symbols.
    def from_molecules_keys
      molecule_cache['molecules.from_molecules_keys']
    end

    # Batches all Molecules cache reads into one SQL query per request, so
    # subsequent fetch calls hit the LocalStore instead of the database.
    def molecule_cache
      Thread.current[:molecule_cache] ||= Rails.cache.fetch_multi(*CACHE_KEYS) do |key|
        case key
        when 'molecules.from_energy_keys'    then Atlas::MoleculeNode.all.select(&:from_energy).map(&:key).sort
        when 'molecules.from_molecules_keys' then Atlas::EnergyNode.all.select(&:from_molecules).map(&:key).sort
        end
      end
    end
  end
end
