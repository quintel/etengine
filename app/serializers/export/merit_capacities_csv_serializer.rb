# frozen_string_literal: true

module Export
  # Capacity CSV for merit order participants. Reuses MeritCSVSerializer
  # filtering (producer/consumer types, curtailment exclusion, NodeCustomisation).
  # Subclass and override +filename+ to produce a named capacity export.
  class MeritCapacitiesCSVSerializer < MeritCSVSerializer
    include ParticipantCapacitiesCSVSerializer
  end
end
