module Qernel::Closud
  class Layer
    def initialize(
        consumers:,
        producers:,
        flexibles: [],
        base: nil,
        peak: Peak::Net
    )
      @base = base
      @consumers = consumers
      @producers = producers
      @flexibles = flexibles
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
      @supply_curve ||=
        total_of([
          negative_only_curve(base_curve),
          @producers,
          @flexibles.map { |flex| positive_only_curve(flex) }
        ].flatten)
    end

    # Public: Curve representing the hourly demand / consumption load for the
    # layer.
    #
    # Returns a Merit::Curve.
    def demand_curve
      @demand_curve ||= total_of([
        positive_only_curve(base_curve),
        @consumers,
        @flexibles.map { |flex| negative_only_curve(flex) }
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
        "#{@producers.length} producers, " \
        "#{@flexibles.length} flexibles)>"
    end

    private

    def total_of(curves)
      if curves.any?
        Merit::CurveTools.add_curves(curves)
      else
        Merit::Curve.new([], 8760)
      end
    end

    # Internal: Given a curve, returns a new curve containing only values
    # greater than zero.
    #
    # For example:
    #   positive_only_curve([-1, 2, 1, -3, 2])
    #   # => [0, 2, 1, 0, 2]
    #
    # Returns a Merit::Curve.
    def positive_only_curve(curve)
      Merit::Curve.new(curve.map { |val| val > 0 ? val : 0.0 })
    end

    # Internal: Given a curve, returns a new curve containing only values less
    # than zero converted to absolutes.
    #
    # For example:
    #   negative_only_curve([-1, 2, 1, -3, 2])
    #   # => [1, 0, 0, 3, 0]
    #
    # Returns a Merit::Curve.
    def negative_only_curve(curve)
      Merit::Curve.new(curve.map { |val| val < 0 ? val.abs : 0.0 })
    end

    # Internal: Returns the base curve.
    def base_curve
      @base && @base.load_curve || Merit::Curve.new([], 8760)
    end
  end
end
