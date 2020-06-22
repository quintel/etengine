# frozen_string_literal: true

module Qernel
  module Reconciliation
    # Creates profiles for use within a Reconciliation calculation. Customises
    # the default Causality::Curves to add support for "self: ..." profiles
    # originating in prior Causality components.
    class Curves < Causality::Curves
      # Public: Retrieves the load profile or curve matching the given profile
      # name.
      #
      # For dynamic curves, a matching method name will be invoked if it exists,
      # otherwise it falls back to the dynamic curve configuration in ETSource.
      #
      # Returns a Merit::Curve.
      def curve(name, node)
        name = name.to_s

        if node.demand&.zero?
          Merit::Curve.new([0.0] * 8760)
        elsif prefix?(name, 'self')
          Merit::Curve.new(self_demand_profile(name[5..-1].to_sym, node))
        else
          super(name, node.node_api)
        end
      end

      private

      # Internal: Constructs a dynamic demand profile using a curve already
      # stored on the node from a previous (fully-completed) calculation.
      # For example, "self: electricity_output_curve" uses the electricity
      # production curve calculated for the node in the electricity merit
      # order.
      #
      # Returns an array.
      def self_demand_profile(name, node)
        Causality::SelfDemandProfile.profile(node.node_api, name)
      end
    end
  end
end
