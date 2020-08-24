# frozen_string_literal: true

module Etsource
  # Loads data relating to the calculation of molecule flows based on the energy graph.
  module Molecules
    module_function

    # Internal: Computes the list of molecule graph nodes which have a molecule_conversion
    # attribute.
    #
    # These nodes will receive a demand based on flows in the energy graph.
    #
    # Returns an Array of Symbols.
    def from_energy_keys
      Rails.cache.fetch('molecules.from_energy_keys') do
        Atlas::MoleculeNode.all.select(&:from_energy).map(&:key).sort
      end
    end

    # Internal: Computes the list of molecule graph nodes which have a molecule_conversion
    # attribute.
    #
    # These nodes will receive a demand based on flows in the energy graph.
    #
    # Returns an Array of Symbols.
    def from_molecules_keys
      Rails.cache.fetch('molecules.from_molecules_keys') do
        Atlas::EnergyNode.all.select(&:from_molecules).map(&:key).sort
      end
    end
  end
end
