# frozen_string_literal: true

# Capacity CSV for electricity merit order participants.
# Reuses MeritCSVSerializer filtering (producer/consumer types,
# curtailment exclusion, NodeCustomisation).
class MeritOrderCapacitiesCSVSerializer < MeritCSVSerializer
  include ParticipantCapacitiesCSVSerializer
end
