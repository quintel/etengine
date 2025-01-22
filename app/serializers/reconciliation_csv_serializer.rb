# frozen_string_literal: true

# Creates CSV rows for hydrogen and network gas.
class ReconciliationCSVSerializer < CausalityCurvesCSVSerializer
  private

  def producer_types
    %i[producer flex export storage transformation]
  end

  def consumer_types
    %i[consumer flex import storage transformation]
  end

  def exclude_producer_subtypes
    %i[curtailment]
  end
end
