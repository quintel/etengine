module Qernel::Closud
  class Layer
    def initialize(consumers:, producers:, base: nil, peak: Peak::Net)
      @base  = base
      @consumers = consumers
      @producers = producers
      @peak = peak
    end

    # Public: Curve representing the hourly net load for the layer.
    #
    # Returns a Merit::Curve.
    def load_curve
      @load_curve ||= demand_curve - supply_curve
    end

    # Public: Curve representing the hourly supply load for the layer.
    #
    # Returns a Merit::Curve.
    def supply_curve
      total_of([
        mapped_base_curve { |val| val < 0 ? -val : 0.0 },
        @producers
      ].flatten)
    end

    # Public: Curve representing the hourly demand / consumption load for the
    # layer.
    #
    # Returns a Merit::Curve.
    def demand_curve
      total_of([
        mapped_base_curve { |val| val > 0 ? val : 0.0 },
        @consumers
      ].flatten)
    end

    # Public: The peak load for the layer.
    #
    # Returns a float.
    def peak_load
      @peak_load ||= @peak.call(self)
    end

    def inspect
      "#<#{self.class.name} (" \
        "#{@consumers.length} consumers, " \
        "#{@producers.length} producers)>"
    end

    private

    # Internal: Returns a new merit curve by mapping over the original with the
    # given block. Returns an flat curve without yielding to the block if no
    # base is set for the layer.
    #
    # For example:
    #   # Returns a curve representing residual production from the base layer.
    #   mapped_base_curve { |val| val < 0 ? -val : 0.0 }
    #
    # Returns a Merit::Curve.
    def mapped_base_curve
      Merit::Curve.new(
        @base ? @base.load_curve.map { |val| yield val } : [],
        8760
      )
    end

    def total_of(curves)
      if curves.any?
        Qernel::Plugins::Merit::Util.add_curves(curves)
      else
        Merit::Curve.new([], 8760)
      end
    end
  end
end
