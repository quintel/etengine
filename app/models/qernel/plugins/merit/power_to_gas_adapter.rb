module Qernel::Plugins
  module Merit
    # An adapter which does not adjust the merit order output for loss, since
    # the converter will account for that instead.
    class PowerToGasAdapter < FlexAdapter
      private

      def output_efficiency
        1.0
      end
    end # PowerToGasAdapter
  end # Merit
end
