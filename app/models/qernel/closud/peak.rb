module Qernel::Closud
  module Peak
    # Determines the peak load of a layer by taking the maximum net hourly load.
    Net = ->(layer) { layer.load_curve.map { |val| val.abs }.max }

    # Determines the peak load of a layer by taking the maximum of the demand or
    # supply.
    Gross = ->(layer) { [layer.supply_curve.max, layer.demand_curve.max].max }
  end
end
