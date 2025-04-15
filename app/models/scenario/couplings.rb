class Scenario < ApplicationRecord
  # Utility methods for couplings
  module Couplings
    def activate_coupling(coupling)
      coupling = coupling.to_s
      self.active_couplings ||= []
      active_couplings << coupling unless active_couplings.include?(coupling)
    end

    def deactivate_coupling(coupling)
      coupling = coupling.to_s
      self.active_couplings ||= []
      active_couplings.delete(coupling)
    end

    def inactive_couplings
      return [] unless coupled?

      coupled_inputs
        .flat_map { |i| Input.coupling_groups_for(i) }
        .uniq
        .map(&:to_s)
        .reject { |cg| active_couplings.include?(cg) }
    end

    # Returns whether any couping sliders are set. Does not check if their
    # coupling is activated or not
    def coupled?
      coupled_inputs.any?
    end

    # Returns an array of input keys that are part of a coupling
    def coupled_inputs
      input_keys = user_values.keys + balanced_values.keys

      Input.coupling_inputs_keys & input_keys
    end

    private

    def validate_coupling_groups
      if active_couplings.any? { |coupling| Input.coupling_groups.exclude?(coupling) }
        errors.add(:coupling_groups, 'invalid coupling')
      end
    end
  end
end
