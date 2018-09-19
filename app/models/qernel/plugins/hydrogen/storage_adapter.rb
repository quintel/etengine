# frozen_string_literal: true

module Qernel::Plugins
  module Hydrogen
    class StorageAdapter < Adapter
      def inspect
        "#<#{self.class.name} #{@converter.key.inspect}>"
      end

      def setup(phase:)
        # Do nothing.
      end

      def inject!(calculator)
        @converter.demand = calculator.storage_out.sum * 3600

        @converter.dataset_lazy_set(:hydrogen_input_curve) do
          calculator.storage_in
        end

        @converter.dataset_lazy_set(:hydrogen_output_curve) do
          calculator.storage_out
        end

        # Set the storage volume.
        crd = calculator.cumulative_residual_demand
        (crd_min, crd_max) = crd.minmax

        storage = @converter.dataset_get(:storage)
        storage.send(:volume=, crd_max - crd_min)

        @converter.dataset_lazy_set(:storage_curve) do
          crd.map { |val| val - crd_min }
        end

        nil
      end
    end
  end
end