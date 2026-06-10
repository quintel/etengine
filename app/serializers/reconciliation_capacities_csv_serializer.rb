# frozen_string_literal: true

# Capacity CSV for hydrogen and network gas participants.
# Reuses ReconciliationCSVSerializer filtering (broader producer/consumer
# types including storage, import, export, etc).
class ReconciliationCapacitiesCSVSerializer < ReconciliationCSVSerializer
  include ParticipantCapacitiesCSVSerializer
end
