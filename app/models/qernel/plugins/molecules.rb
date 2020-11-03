# frozen_string_literal: true

module Qernel
  module Plugins
    # Graph plugin which coordinates the calculation of flows in the molecule graph.
    #
    # The graph calcualtion process is:
    #
    # 1. Calculate energy graph.
    # 2. Set molecule graph demands based on (1).
    # 3. Calculate molecule graph.
    # 4. Set energy graph demands based on (2).
    # 5. Other energy graph plugins (i.e., Causality).
    # 6. Re-calculate energy graph, PRESERVING demands set in (4).
    # 7. Set molecule graph demands based on (6).
    # 8. Re-calculate molecule graph.
    #
    # The Molecules plugin is responsible for steps 2-4, 7, and 8.
    #
    # When Causality is enabled, the dataset used by the molecule graph will be snapshoted prior to
    # the first calculation, containing the result of any inputs set by end-users. The dataset will
    # be restored by Causality prior to the final calculation of the molecule graph; therefore there
    # is no need for Molecules to snapshot the dataset itself.
    class Molecules
      include Plugin

      after :first_calculation, :calculate
      after :change_dataset, :reinstall_energy_demands
      after :finish, :calculate_final

      def self.enabled?(graph)
        graph.energy?
      end

      def molecule_graph
        @molecule_graph ||= create_molecule_graph
      end

      private

      def calculate
        return unless run? && Qernel::Plugins::Causality.enabled?(@graph)

        @calculation = Qernel::Molecules::Calculation.new(@graph, molecule_graph)
        @calculation.run
      end

      def reinstall_energy_demands
        molecule_graph.dataset = @graph.dataset
        @calculation&.reinstall_demands
      end

      def calculate_final
        Qernel::Molecules::FinalCalculation.new(@graph, molecule_graph).run if run?
      end

      def run?
        # Dataset is nil in some tests. Skip the molecule graph calculation.
        !Rails.env.test? || @graph.dataset.present?
      end

      def create_molecule_graph
        graph = Etsource::Loader.instance.molecule_graph
        graph.dataset = @graph.dataset
        graph
      end
    end
  end
end
