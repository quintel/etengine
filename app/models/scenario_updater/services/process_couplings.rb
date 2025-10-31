# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Processes coupling logic: activates couplings and determines uncoupled inputs.
    # Returns a hash with coupling state information without mutating the scenario.
    class ProcessCouplings
      include Dry::Monads[:result]

      TRUTHY_VALUES = Set.new([true, 'true', '1']).freeze

      def call(scenario, provided_values, active_couplings, uncouple)
        # Compute active couplings list
        active_couplings_list = compute_active_couplings(active_couplings)

        # Compute couplings to activate from provided values
        couplings_to_activate = compute_couplings_to_activate(scenario, provided_values)

        # Compute uncoupled inputs
        uncoupled_inputs = compute_uncoupled_inputs(scenario, uncouple)

        Success({
          active_couplings: active_couplings_list,
          couplings_to_activate: couplings_to_activate,
          uncoupled_inputs: uncoupled_inputs
        })
      end

      private

      def compute_active_couplings(active_couplings)
        return nil if active_couplings.nil?
        return [] if active_couplings == []

        Array(active_couplings).map(&:to_sym)
      end

      def compute_couplings_to_activate(scenario, provided_values)
        couplings_to_activate = []

        provided_values.each do |key, _|
          groups = Input.coupling_groups_for(key)
          next if groups.blank?

          groups.each do |group|
            next if scenario.inactive_couplings.include?(group)
            couplings_to_activate << group unless couplings_to_activate.include?(group)
          end
        end

        couplings_to_activate
      end

      def compute_uncoupled_inputs(scenario, uncouple)
        return [] unless TRUTHY_VALUES.include?(uncouple)

        scenario.coupled_inputs
      end
    end
  end
end
