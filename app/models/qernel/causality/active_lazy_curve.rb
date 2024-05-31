# frozen_string_literal: true

module Qernel
  module Causality
    # A lazy curve that allows external factors to overwrite calculated values
    class ActiveLazyCurve < LazyCurve
      def []=(frame, value)
        @values[frame] = value if @values[frame]
      end
    end
  end
end
