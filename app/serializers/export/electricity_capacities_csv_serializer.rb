# frozen_string_literal: true

module Export
  # Capacity CSV for electricity merit order participants.
  class ElectricityCapacitiesCSVSerializer < MeritCapacitiesCSVSerializer
    def filename
      :electricity_capacities
    end
  end
end
