# frozen_string_literal: true

module Qernel
  module Causality
    # Wrapper around the three heat networks that clears them in order of HT, MT, LT
    #
    # They are in a wrapper, because if they have to be mixed at a later stage
    # we have them grouped here already
    class HeatNetworkWrapper
      def initialize(graph)
        @heat_networks =
          [
            Qernel::Causality::HeatNetwork::HighTemperature.new(graph),
            Qernel::Causality::HeatNetwork::MediumTemperature.new(graph),
            Qernel::Causality::HeatNetwork::LowTemperature.new(graph)
          ]
      end

      def setup
        @heat_networks.each(&:setup)
      end

      def setup_dynamic
        @heat_networks.each(&:setup_dynamic)
      end

      def inject_values!
        @heat_networks.each(&:inject_values!)
      end

      def calculate_frame(frame)
        network_calculators.each { |calc| calc.call(frame) }
      end

      # Public: Returns the Qernel::Causality::HeatNetwork Manager for the given
      # node if it's connected to a heat network.
      #
      # Raises when the node was not connected to any heat network
      def manager_for(node)
        index = ordered_keys.find_index { |network| node.public_send(network) }

        raise "Missing participant: undefined heat network for: #{node.key}" if index.nil?

        @heat_networks[index]
      end

      private

      def network_calculators
        @network_calculators ||= @heat_networks.map do |network|
          Merit::StepwiseCalculator.new.calculate(
            network.order
          )
        end
      end

      # Internal: returns the keys of the heat networks in the same order as @heat_networks
      #
      # IDEA: check which network is most common and have that one as the first for optimisation
      def ordered_keys
        %i[heat_network_ht heat_network_mt heat_network_lt]
      end
    end
  end
end
