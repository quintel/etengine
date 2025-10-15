# frozen_string_literal: true

module ScenarioUpdater
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
    end
  end
end
