# frozen_string_literal: true

class ScenarioUpdater
  module Inputs
    # Manages the activation and deactivation of input coupling groups for scenarios.
    class CouplingsManager < Base
      TRUTHY_VALUES = Set.new([true, 'true', '1']).freeze

      def activate_from_provided_values(provided_values)
        provided_values.each do |key, _|
          groups = Input.coupling_groups_for(key)
          next if groups.blank?

          groups.each do |group|
            next if scenario.inactive_couplings.include?(group)
            scenario.activate_coupling(group)
          end
        end
      end

      def uncoupled_inputs
        return [] unless uncouple?
        scenario.coupled_inputs
      end

      def uncouple?
        TRUTHY_VALUES.include?(params.fetch(:uncouple, false))
      end

      def uncoupled_base_user_values(base_values)
        values = base_values.dup

        if uncouple?
          values.except!(*uncoupled_inputs)
        else
          values
        end
      end

      def uncoupled_base_balanced_values(base_values)
        values = base_values.dup

        if uncouple?
          values.except!(*scenario.coupled_inputs)
        else
          values
        end
      end

      # Applies a specific list of active couplings to the scenario
      def apply_active_couplings_list!
        return unless params[:scenario]&.key?(:active_couplings)

        couplings_list = params[:scenario][:active_couplings]
        return unless couplings_list

        # Clear all active couplings
        scenario.active_couplings = []

        # Activate each coupling specified in the list
        Array(couplings_list).each do |coupling|
          scenario.activate_coupling(coupling.to_sym)
        end
      end
    end
  end
end
