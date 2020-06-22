# frozen_string_literal: true

module Qernel
  module Reconciliation
    class StorageAdapter < Adapter
      def inspect
        "#<#{self.class.name} #{@node.key.inspect}>"
      end

      def setup(phase:)
        # Do nothing.
      end

      def inject!(calculator)
        @node.demand = calculator.storage_out.sum * 3600

        return inject_zero_storage! if @node.demand.zero?

        @node.dataset_lazy_set(@context.curve_name(:input)) do
          calculator.storage_in
        end

        @node.dataset_lazy_set(@context.curve_name(:output)) do
          calculator.storage_out
        end

        # Set the storage volume.
        (cs_min, cs_max) = calculator.cumulative_surplus.minmax

        inject_storage(cs_max - cs_min) { calculator.storage_volume }

        nil
      end

      private

      # Internal: In the event that there is no storage (almost certainly there
      # is no carrier energy in the scenario), set empty curves.
      def inject_zero_storage!
        null_curve = Array.new(8760, 0.0)

        @node.dataset_set(@context.curve_name(:input), null_curve)
        @node.dataset_set(@context.curve_name(:output), null_curve)

        inject_storage(0.0) { Array.new(8760, 0.0) }
      end

      # Sets the amount of storage. Provide a block which will lazily set the
      # storage curve.
      def inject_storage(volume, &curve)
        storage = @node.dataset_get(:storage)
        storage.send(:volume=, volume)

        @node.dataset_lazy_set(:storage_curve, &curve)

        nil
      end
    end
  end
end
