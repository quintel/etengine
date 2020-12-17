# frozen_string_literal: true

# Creates CSV rows describing hydrogen production.
class ReconciliationCSVSerializer < CurvesCSVSerializer
  private

  def producer_types
    %i[producer import storage]
  end

  def consumer_types
    %i[consumer export storage]
  end
end
