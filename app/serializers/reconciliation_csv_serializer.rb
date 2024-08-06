# frozen_string_literal: true

# Creates CSV rows describing hydrogen production.
class ReconciliationCSVSerializer < CausalityCurvesCSVSerializer
  private

  def producer_types
    %i[producer flex]
  end

  def consumer_types
    %i[consumer flex]
  end

  def exclude_producer_subtypes
    %i[curtailment]
  end
end
