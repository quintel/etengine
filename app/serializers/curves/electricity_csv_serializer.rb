# frozen_string_literal: true

module Curves
  # Hourly curve CSV for electricity merit order participants.
  # Reuses MeritCSVSerializer filtering (producer/consumer types,
  # curtailment exclusion, NodeCustomisation).
  class ElectricityCSVSerializer < MeritCSVSerializer
    def filename
      :electricity_profiles
    end
  end
end
