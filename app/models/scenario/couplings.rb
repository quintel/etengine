class Scenario < ApplicationRecord
  # Utility methods for couplings
  module Couplings
    # Add validation via Atlas//ETsource -> list all available couplings
    def activate_coupling(coupling)
      active_couplings << coupling unless active_couplings.include?(coupling)
    end

    def deactivate_coupling(coupling)
      active_couplings.delete(coupling)
    end

    def inactive_couplings
      return [] unless coupled?

      coupled_inputs
        .flat_map { |i| Input.coupling_groups_for(i) }
        .uniq
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
  end
end
