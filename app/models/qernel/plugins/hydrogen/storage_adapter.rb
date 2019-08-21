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

        return inject_zero_storage! if @converter.demand.zero?

        @converter.dataset_lazy_set(:hydrogen_input_curve) do
          calculator.storage_in
        end

        @converter.dataset_lazy_set(:hydrogen_output_curve) do
          calculator.storage_out
        end

        # Set the storage volume.
        (cs_min, cs_max) = calculator.cumulative_surplus.minmax

        inject_storage(cs_max - cs_min) { calculator.storage_volume }

        nil
      end

      private

      # Internal: In the event that there is no storage (almost certainly there
      # is no hydrogen in the scenario), set empty curves.
      def inject_zero_storage!
        null_curve = Array.new(8760, 0.0)

        @converter.dataset_set(:hydrogen_input_curve, null_curve)
        @converter.dataset_set(:hydrogen_output_curve, null_curve)

        inject_storage(0.0) { Array.new(8760, 0.0) }
      end

      # Sets the amount of storage. Provide a block which will lazily set the
      # storage curve.
      def inject_storage(volume, &curve)
        storage = @converter.dataset_get(:storage)
        storage.send(:volume=, volume)

        @converter.dataset_lazy_set(:storage_curve, &curve)

        nil
      end
    end
  end
end
